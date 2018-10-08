#!/bin/bash

ghdl --remove
ghdl -a --std=08 midi/midi.vhd \
     midi/byte_classifier.vhd \
     midi/byte_classifier_tests.vhd \
     midi/event_builder.vhd \
     midi/event_builder_tests.vhd

echo ""
echo "RUNNING TESTS FOR: byte_classifier"
echo "----------------------------------"

ghdl -e --std=08 byte_classifier_tests
ghdl -r --std=08 byte_classifier_tests

echo ""
echo "RUNNING TESTS FOR: event_builder"
echo "--------------------------------"

ghdl -e --std=08 event_builder_tests
ghdl -r --std=08 event_builder_tests
