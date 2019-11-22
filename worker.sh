#!lib/test-in-container-systemd.sh

set -ex

systemctl enable --now postgresql

su postgres -c "createuser -D $dbuser" 
su postgres -c "createdb -O $dbuser $dbname"

aa-complain /usr/share/openqa/script/openqa
aa-complain /usr/share/openqa/script/worker

systemctl enable --now apache2.service
systemctl enable --now openqa-webui.service
systemctl enable --now openqa-websockets.service
systemctl enable --now openqa-scheduler.service
systemctl enable --now openqa-livehandler.service
systemctl enable --now openqa-gru.service

# wait for webui to become available
sleep 2
attempts_left=10
while ! curl -sI http://localhost/ | grep 200 ; do
    sleep 3
    : $((attempts_left--))
    [ "$attempts_left" -gt 0 ] || {
        service openqa-webui status
        exit 1
    }
done

# this must create default user
curl -sI http://localhost/login

# create api key - the table will be available after webui service startup
API_KEY=$(hexdump -n 8 -e '2/4 "%08X" 1 "\n"' /dev/urandom)
API_SECRET=$(hexdump -n 8 -e '2/4 "%08X" 1 "\n"' /dev/urandom)
echo "INSERT INTO api_keys (key, secret, user_id, t_created, t_updated) VALUES ('${API_KEY}', '${API_SECRET}', 2, NOW(), NOW());" | su postgres -c "psql $dbname"

cat >> /etc/openqa/client.conf <<EOF
[localhost]
key = ${API_KEY}
secret = ${API_SECRET}
EOF

mkdir -p /root/.config/openqa
cp /etc/openqa/client.conf /root/.config/openqa/
mkdir -p /var/lib/openqa/.config/openqa/
cp /etc/openqa/client.conf /var/lib/openqa/.config/openqa/
chown "$dbuser" /var/lib/openqa/.config/openqa/client.conf


systemctl enable --now openqa-worker@1.service

sleep 5

systemctl status openqa-worker@1
