#!/bin/bash
set -e

rails db:migrate
rails server -b 0.0.0.0
