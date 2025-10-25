run:
		bash github2markdown.sh skepticspriggan issues

watch:
		echo github2markdown.sh | entr bash github2markdown.sh --token "$$(pass github/token)" --username skepticspriggan

install : ${HOME}/.local/bin/github2markdown

${HOME}/.local/bin/github2markdown:
		ln -s -n -f ${PWD}/github2markdown.sh ${HOME}/.local/bin/github2markdown
		chmod +x github2markdown.sh
