#!/bin/bash
docker exec -it ansible bash -c "cd /ansible && ansible-playbook -i inventory/hosts.ini playbooks/playbook_backend.yml && ansible-playbook -i inventory/hosts.ini playbooks/playbook_lb.yml && ansible-playbook -i inventory/hosts.ini playbooks/playbook_exporters.yml && ansible-playbook -i inventory/hosts.ini playbooks/playbook_monitoring.yml && ansible-playbook -i inventory/hosts.ini playbooks/playbook_cluster.yml"
docker restart lb1 lb2
