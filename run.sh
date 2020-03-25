docker run --rm -it \
	-v $HOME/notebooks:/notebooks \
	-w /tmp  \
	-p 8888:8888 \
	-v ~/.m2:/var/maven/.m2 \
	-e MAVEN_CONFIG=/var/maven/.m2 \
	-e MAVEN_OPTS="-Duser.home=/var/maven" \
	brunoe/jupyterjava 
	
