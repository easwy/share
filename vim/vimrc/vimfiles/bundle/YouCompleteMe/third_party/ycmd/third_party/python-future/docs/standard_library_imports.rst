.. _standard-library-imports:

Standard library imports
------------------------

:mod:`future` supports the standard library reorganization (PEP 3108) through
several mechanisms.

.. _direct-imports:

Direct imports
~~~~~~~~~~~~~~

As of version 0.14, the ``future`` package comes with top-level packages for
Python 2.x that provide access to the reorganized standard library modules
under their Python 3.x names.

Direct imports are the preferred mechanism for accesing the renamed standard
library modules in Python 2/3 compatible code. For example, the following clean
Python 3 code runs unchanged on Python 2 after installing ``future``::

    >>> # Alias for future.builtins on Py2:
    >>> from builtins import str, open, range, dict

    >>> # Top-level packages with Py3 names provided on Py2:
    >>> import queue
    >>> import configparser
    >>> import tkinter.dialog
    >>> etc.

Notice that this code actually runs on Python 3 without the presence of the
``future`` package.

Of the 44 modules that were refactored with PEP 3108 (standard library
reorganization), 30 are supported with direct imports in the above manner. The
complete list is here::

    ### Renamed modules:

    import builtins

    import configparser
    import copyreg

    import html
    import html.entities
    import html.parser

    import http.client
    import http.cookies
    import http.cookiejar
    import http.server

    import queue

    import reprlib

    import socketserver

    from tkinter import colorchooser
    from tkinter import commondialog
    from tkinter import constants
    from tkinter import dialog
    from tkinter import dnd
    from tkinter import filedialog
    from tkinter import font
    from tkinter import messagebox
    from tkinter import scrolledtext
    from tkinter import simpledialog
    from tkinter import tix
    from tkinter import ttk

    import winreg                    # Windows only

    import xmlrpc.client
    import xmlrpc.server

    import _dummy_thread
    import _markupbase
    import _thread


.. _list-standard-library-refactored:

Aliased imports
~~~~~~~~~~~~~~~

The following 14 modules were refactored or extended from Python 2.6/2.7 to 3.x
but were neither renamed in Py3.x nor were the new APIs backported to Py2.x.
This precludes compatibility interfaces that work out-of-the-box. Instead, the
``future`` package makes the Python 3.x APIs available on Python 2.x as
follows::

    from future.standard_library import install_aliases
    install_aliases()

    from collections import UserDict, UserList, UserString

    import urllib.parse
    import urllib.request
    import urllib.response
    import urllib.robotparser
    import urllib.error

    import dbm
    import dbm.dumb
    import dbm.gnu                # requires Python dbm support
    import dbm.ndbm               # requires Python dbm support

    from itertools import filterfalse, zip_longest

    from subprocess import getoutput, getstatusoutput

    from sys import intern

    import test.support


The newly exposed ``urllib`` submodules are backports of those from Py3.x.
This means, for example, that ``urllib.parse.unquote()`` now exists and takes
an optional ``encoding`` argument on Py2.x as it does on Py3.x.

**Limitation:** Note that the ``http``-based backports do not currently support
HTTPS (as of 2015-09-11) because the SSL support changed considerably in Python
3.x. If you need HTTPS support, please use this idiom for now::

    from future.moves.urllib.request import urlopen

Backports also exist of the following features from Python 3.4:

- ``math.ceil`` returns an int on Py3
- ``collections.OrderedDict``  (for Python 2.6)
- ``collections.Counter``      (for Python 2.6)
- ``collections.ChainMap``     (for all versions prior to Python 3.3)
- ``itertools.count``          (for Python 2.6, with step parameter)
- ``subprocess.check_output``  (for Python 2.6)
- ``reprlib.recursive_repr``   (for Python 2.6 and 2.7)

These can then be imported on Python 2.6+ as follows::

    from future.standard_library import install_aliases
    install_aliases()

    from math import ceil      # now returns an int
    from collections import Counter, OrderedDict, ChainMap
    from itertools import count
    from subprocess import check_output
    from reprlib import recursive_repr


External standard-library backports
-----------------------------------

Backports of the following modules from the Python 3.x standard library are
available independently of the python-future project::

    import enum                       # pip install enum34
    import singledispatch             # pip install singledispatch
    import pathlib                    # pip install pathlib

A few modules from Python 3.4 and 3.3 are also available in the ``backports``
package namespace after ``pip install backports.lzma`` etc.::

    from backports import lzma
    from backports import functools_lru_cache as lru_cache

The following Python 2.6 backports of standard library packages from Python 2.7+
are also available::

    import argparse                   # pip install argparse
    import importlib                  # pip install importlib
    import unittest2 as unittest      # pip install unittest2

These are included in Python 2.7 and Python 3.x.


Included full backports
-----------------------

Alpha-quality full backports of the following modules from Python 3.3's
standard library to Python 2.x are also available in ``future.backports``::

    http.client
    http.server
    html.entities
    html.parser
    urllib
    xmlrpc.client
    xmlrpc.server
 
The goal for these modules, unlike the modules in the ``future.moves`` package
or top-level namespace, is to backport new functionality introduced in Python
3.3.

If you need the full backport of one of these packages, please open an issue `here
<https://github.com/PythonCharmers/python-future>`_.

