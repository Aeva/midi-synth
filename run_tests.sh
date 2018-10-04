#!/bin/bash

ghdl --remove
ghdl -a midi/midi.vhd \
     midi/byte_classifier.vhd \
     midi/byte_classifier_tests.vhd \
     
ghdl -e byte_classifier_tests
ghdl -r byte_classifier_tests --stop-time=10sec
