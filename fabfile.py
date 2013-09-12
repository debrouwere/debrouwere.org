from fabric.api import *

env.use_ssh_config = True
env.hosts = ['jerez']

def push():
    local('git add .; git push')
    local('coffee tools/shorten.coffee')
    with lcd('../writing'):
        local('git add .; git commit -am "Add new shortlinks."')
        local('git push')

def pull():
    with cd('/home/ubuntu/stdout.be/writing'):
        run('git pull')
    with cd('/home/ubuntu/stdout.be/platform'):
        run('git pull')   

def build():
    with cd('/home/ubuntu/stdout.be/platform'):
        sudo('hector .')

def reload():
    sudo('service nginx reload')

def update():
    push()
    pull()
    build()
    reload()