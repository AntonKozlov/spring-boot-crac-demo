#!/usr/bin/env bash
set -e

case $(uname -m) in
    arm64)   url="https://cdn.azul.com/zulu/bin/zulu17.42.21-ca-crac-jdk17.0.7-linux_aarch64.tar.gz" ;;
    *)       url="https://cdn.azul.com/zulu/bin/zulu17.42.21-ca-crac-jdk17.0.7-linux_x64.tar.gz" ;;
esac

echo "Using CRaC enabled JACK $url"

./mvnw clean package
docker build -t sdeleuze/spring-boot-crac-demo:builder --build-arg CRAC_JDK_URL=$url .
docker run -d --cap-add=CHECKPOINT_RESTORE --cap-add=SYS_ADMIN --cap-add=SYS_PTRACE --rm --name=spring-boot-crac-demo --ulimit nofile=1024 -p 8080:8080 -v $(pwd)/target:/opt/mnt sdeleuze/spring-boot-crac-demo:builder
echo "Please wait during creating the checkpoint..."
sleep 10
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=spring-boot-crac-demo") sdeleuze/spring-boot-crac-demo:checkpoint
docker kill $(docker ps -qf "name=spring-boot-crac-demo")
