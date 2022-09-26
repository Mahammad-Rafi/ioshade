#!/usr/bin/expect
#
# $Header: oak/src/pkg/src/rootpasswd.sh /main/1 2012/08/14 18:44:36 ssingla Exp $
#
# rootpasswd.sh
#
# Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      rootpasswd.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    ssingla     08/01/12 - rootpassord setting
#    ssingla     08/01/12 - Creation
#

spawn passwd
expect "assword:"
send "welcome1\r"
expect "assword:"
send "welcome1\r"
send "\r"
expect eof

