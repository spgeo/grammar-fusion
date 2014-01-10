GrammarFusion
=============

Collaboration project between UNIBI and TSI-TUC to work on the fusion of grammars from a button-up and a top-down approach.

The used en.abnf for the travel domain is taken from https://sites.google.com/site/portdial2/deliverables-publications/free-data-deliverable/grammar.en.tar?attredirects=0

Start with:
python start.py input_BU input_TD groundtruth


Fusion Strategies:
============
Currently two different fusion strategies are implemented.
First a simple union of two grammars. And as second strategie, the augmention of one grammar with the other grammar.


Dependencies:
============
- pdflatex
