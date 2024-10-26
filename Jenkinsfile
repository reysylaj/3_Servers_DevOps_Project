/*execute shell*/

/*First Job*/
ssh userofserver@192.168.0.207 <<EOF
    cd /pathofterraform
    terraform init
    terraform apply -auto-approve 
EOF

/*Second Job*/
ssh userofserver@192.168.0.38 <<EOF
    cd /pathofansible
    ansible-playbook playbook.yml -i inventory.ini
EOF