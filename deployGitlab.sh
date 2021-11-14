mkdir /home/vagrant/gitlab
export GITLAB_HOME=/srv/gitlab
export GITLAB_HOME=/home/vagrant/gitlab
cd $GITLAB_HOME

cat > docker-compose.yml << EOF
version: '3.5'
services:
 gitlab:
  image: 'gitlab/gitlab-ee:latest'
  restart: always
  hostname: 'gitlab.weslao.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://gitlab.weslao.com'
      # Add any other gitlab.rb configuration here, each on its own line
  ports:
    - '80:80'
    - '443:443'
    - '2222:2222'
  volumes:
    - '$GITLAB_HOME/config:/etc/gitlab'
    - '$GITLAB_HOME/logs:/var/log/gitlab'
    - '$GITLAB_HOME/data:/var/opt/gitlab'
EOF

docker-compose up -d
#Senha inicial: docker exec -it gitlab_gitlab_1 cat /etc/gitlab/initial_root_password
