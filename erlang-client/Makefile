#   The contents of this file are subject to the Mozilla Public License
#   Version 1.1 (the "License"); you may not use this file except in
#   compliance with the License. You may obtain a copy of the License at
#   http://www.mozilla.org/MPL/
#
#   Software distributed under the License is distributed on an "AS IS"
#   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#   License for the specific language governing rights and limitations
#   under the License.
#
#   The Original Code is the RabbitMQ Erlang Client.
#
#   The Initial Developers of the Original Code are LShift Ltd.,
#   Cohesive Financial Technologies LLC., and Rabbit Technologies Ltd.
#
#   Portions created by LShift Ltd., Cohesive Financial
#   Technologies LLC., and Rabbit Technologies Ltd. are Copyright (C) 
#   2007 LShift Ltd., Cohesive Financial Technologies LLC., and Rabbit 
#   Technologies Ltd.; 
#
#   All Rights Reserved.
#
#   Contributor(s): Ben Hood <0x6e6562@gmail.com>.
#

EBIN_DIR=ebin
SOURCE_DIR=src
INCLUDE_DIR=include
INCLUDE_SERV_DIR=rabbitmq_server/include
DIST_DIR=erlang-client

LOAD_PATH=ebin rabbitmq_server/ebin

INCLUDES=$(wildcard $(INCLUDE_DIR)/*.hrl)
SOURCES=$(wildcard $(SOURCE_DIR)/*.erl)
TARGETS=$(patsubst $(SOURCE_DIR)/%.erl, $(EBIN_DIR)/%.beam,$(SOURCES))

ifndef USE_SPECS
# our type specs rely on features / bug fixes in dialyzer that are
# only available in R12B-3 upwards
#
# NB: the test assumes that version number will only contain single digits
USE_SPECS=$(shell if [ $$(erl -noshell -eval 'io:format(erlang:system_info(version)), halt().') \> "5.6.2" ]; then echo "true"; else echo "false"; fi)
endif

ERLC_OPTS=-I $(INCLUDE_DIR) -I $(INCLUDE_SERV_DIR) -o $(EBIN_DIR) -Wall -v +debug_info $(shell [ $(USE_SPECS) = "true" ] && echo "-Duse_specs")

BROKER_DIR=../rabbitmq-server
BROKER_SYMLINK=rabbitmq_server

NODENAME=rabbit_test_direct
MNESIA_DIR=/tmp/rabbitmq_$(NODENAME)_mnesia
LOG_BASE=/tmp

ERL_CALL=erl_call -sname $(NODENAME) -e

PLT=$(HOME)/.dialyzer_plt


all: compile

dialyze: $(EBIN_DIR) $(TARGETS)
	dialyzer --plt $(PLT) -c $(TARGETS)

dialyze_all: $(EBIN_DIR) $(TARGETS) $(TEST_TARGETS)
	dialyzer --plt $(PLT) -c $(TARGETS) $(TEST_TARGETS)

add_broker_to_plt: $(BROKER_SYMLINK)/ebin
	dialyzer --add_to_plt --plt $(PLT) -r $<

compile: $(EBIN_DIR) $(TARGETS)

$(BROKER_SYMLINK):
ifdef BROKER_DIR
	ln -sf $(BROKER_DIR) $(BROKER_SYMLINK)
endif

$(EBIN_DIR):
	mkdir -p $@

$(EBIN_DIR)/%.beam: $(SOURCE_DIR)/%.erl $(INCLUDES) $(BROKER_SYMLINK)
	erlc $(ERLC_OPTS) $<

$(EBIN_DIR)/%.beam: $(TEST_SOURCE_DIR)/%.erl $(INCLUDES) $(BROKER_SYMLINK)
	erlc $(ERLC_OPTS) $<

run:
	erl -pa $(LOAD_PATH)

clean:
	rm -f $(EBIN_DIR)/*.beam
	rm -f rabbitmq_server erl_crash.dump
	rm -fr cover dist

source_tarball:
	mkdir -p dist/$(DIST_DIR)
	cp -a README Makefile src/*.erl include/*.hrl dist/$(DIST_DIR)
	cd dist ; tar cvzf $(DIST_DIR).tar.gz $(DIST_DIR)
