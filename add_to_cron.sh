#write out current crontab
crontab -l > mycron
#echo new cron into cron file
#В 0 минуту каждого часа будет выполнятся скрипт
echo "0 * * * * source '/home/kukuruzzo/OTUS/OTUS_LP_HW_10/script.sh'" >> mycron
#install new cron file
crontab mycron
rm mycron