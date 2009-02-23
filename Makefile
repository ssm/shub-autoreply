clean:

check:
	ruby -cw shub-autoreply.rb

install: check
	install -d $(DESTDIR)/etc/shub-autoreply/templates
	install -d $(DESTDIR)/usr/local/bin
	install -o root -g root -m 0755 shub-autoreply.rb $(DESTDIR)/usr/bin/shub-autoreply
	install -o root -g root -m 0755 shub-autoreply.conf $(DESTDIR)/etc/shub-autoreply/shub-autoreply.conf
