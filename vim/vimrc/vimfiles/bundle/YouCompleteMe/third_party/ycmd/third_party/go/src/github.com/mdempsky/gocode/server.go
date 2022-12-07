package main

import (
	"bytes"
	"fmt"
	"go/importer"
	"go/types"
	"log"
	"net"
	"net/rpc"
	"os"
	"os/signal"
	"runtime/debug"
	"time"

	"github.com/mdempsky/gocode/internal/gbimporter"
	"github.com/mdempsky/gocode/internal/suggest"
)

func doServer() {
	addr := *g_addr
	if *g_sock == "unix" {
		addr = getSocketPath()
	}

	lis, err := net.Listen(*g_sock, addr)
	if err != nil {
		log.Fatal(err)
	}

	sigs := make(chan os.Signal)
	signal.Notify(sigs, os.Interrupt)
	go func() {
		<-sigs
		exitServer()
	}()

	if err = rpc.Register(&Server{}); err != nil {
		log.Fatal(err)
	}
	rpc.Accept(lis)
}

func exitServer() {
	if *g_sock == "unix" {
		_ = os.Remove(getSocketPath())
	}
	os.Exit(0)
}

type Server struct {
}

type AutoCompleteRequest struct {
	Filename string
	Data     []byte
	Cursor   int
	Context  gbimporter.PackedContext
	Source   bool
	Builtin  bool
}

type AutoCompleteReply struct {
	Candidates []suggest.Candidate
	Len        int
}

func (s *Server) AutoComplete(req *AutoCompleteRequest, res *AutoCompleteReply) error {
	defer func() {
		if err := recover(); err != nil {
			fmt.Printf("panic: %s\n\n", err)
			debug.PrintStack()

			res.Candidates = []suggest.Candidate{
				{Class: "PANIC", Name: "PANIC", Type: "PANIC"},
			}
		}
	}()
	if *g_debug {
		var buf bytes.Buffer
		log.Printf("Got autocompletion request for '%s'\n", req.Filename)
		log.Printf("Cursor at: %d\n", req.Cursor)
		buf.WriteString("-------------------------------------------------------\n")
		buf.Write(req.Data[:req.Cursor])
		buf.WriteString("#")
		buf.Write(req.Data[req.Cursor:])
		log.Print(buf.String())
		log.Println("-------------------------------------------------------")
	}
	now := time.Now()
	var underlying types.ImporterFrom
	if req.Source {
		underlying = importer.For("source", nil).(types.ImporterFrom)
	} else {
		underlying = importer.Default().(types.ImporterFrom)
	}
	cfg := suggest.Config{
		Importer: gbimporter.New(&req.Context, req.Filename, underlying),
		Builtin:  req.Builtin,
	}
	if *g_debug {
		cfg.Logf = log.Printf
	}
	candidates, d := cfg.Suggest(req.Filename, req.Data, req.Cursor)
	elapsed := time.Since(now)
	if *g_debug {
		log.Printf("Elapsed duration: %v\n", elapsed)
		log.Printf("Offset: %d\n", res.Len)
		log.Printf("Number of candidates found: %d\n", len(candidates))
		log.Printf("Candidates are:\n")
		for _, c := range candidates {
			log.Printf("  %s\n", c.String())
		}
		log.Println("=======================================================")
	}
	res.Candidates, res.Len = candidates, d
	return nil
}

type ExitRequest struct{}
type ExitReply struct{}

func (s *Server) Exit(req *ExitRequest, res *ExitReply) error {
	go func() {
		time.Sleep(time.Second)
		exitServer()
	}()
	return nil
}
