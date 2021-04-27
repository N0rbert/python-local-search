# python-local-search
Bash script for searching locally installed Python documentation on Debian-based systems such as Ubuntu

It is known that Python have a variety of possible documentation formats. For some Python packages it is possible to use [Devhelp](https://packages.ubuntu.com/search?suite=all&exact=1&searchon=names&keywords=devhelp) or [DocHelp](https://packages.ubuntu.com/search?suite=all&section=all&arch=any&keywords=dochelp&searchon=names), for some - not.

This script allows one to run first preliminary full-text search to get Python package name and way to read the relevant documentation in the HTML-format.

It uses `aptitude` for Python package selection, `html2text` and/or `pandoc` packages to run the conversion from HTML to plain-text to get better search results.

The script shows found local HTML documents in default web-browser and provides information about further methods of documentation reading - via DevHelp, DocHelp or web-browser.
