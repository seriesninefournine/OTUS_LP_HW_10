#!/bin/bash

#vars
homedir='/home/kukuruzzo/OTUS/OTUS_LP_HW_10/'
configfile=$homedir'reportinfo.cfg'
logfile=$homedir'access-4560-644067.log'
outputfileIP=''
outputfileAddress=''
outputfileErrors=''
outputfileErrorsCount=''
email="lesson@otus.ru"
outputlog=''
reportdate=0

#Проверяем мультизапуск
if [ $(ps -x | grep -E "bash $0" | wc -l) -gt 3 ]; then
    echo "Скрипт уже запущен"
    exit
fi

#Сортируем и записываем полученый файл
function SortAndSave { 
    if [ -e $1 ]; then
        sort -n $1 | uniq -c | sort -rn -o$1
    else 
        echo "No new data from $(date -d@$reportdate +"%Y-%m-%d")_$(date -d@$reportdate +"%H-%M-%S")" >> $1
    fi
}

#Читаем время последней выгрузки
if [ -e $configfile ]; then
    if  grep -qo '^reportdate\s.\s[0-9]*' $configfile ; then
        reportdate=$(grep -o '^reportdate\s.\s[0-9]*' $configfile | cut -f 3 -d " ")
    else 
        echo "reportdate = $reportdate" >> $configfile
    fi
else
    echo "reportdate = $reportdate" >> $configfile
fi

outputfileIP="ip_address_log_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S").log"
outputfileAddress="address_log_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S").log"
outputfileErrors="errors_log_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S").log"
outputfileErrorsCount="errors_count_log_$(date +"%Y-%m-%d")_$(date +"%H-%M-%S").log"

#формируем выгрузку в файлы
while read line; do
datetime=$(echo $line | cut -f 1 -d ']' | cut -f 2 -d '[' |sed -e 's|/| |g' | sed -e 's|:| |' | xargs -I mydate date --date="mydate" +%s)
IPaddress=$(echo $line | cut -f 1 -d ' ')
Address=$(echo $line | grep -E  -o 'GET /.*\sH' | cut -f 2 -d " ")
Error=$(echo $line | grep -E -o '\s[[:digit:]]{3}\s')
if [ "$reportdate" -gt "$datetime" ]; then
    continue
fi

if [ "$Error" -ne "200" ]; then
    echo -e  "$line" >> $homedir$outputfileErrors
fi

echo -e  "$Error" >> $homedir$outputfileErrorsCount
echo -e  "$IPaddress" >> $homedir$outputfileIP
echo -e  "$Address" >> $homedir$outputfileAddress
done < $logfile

#устанавливаем reportdata на момент отчета
sed -i "s|^reportdate\s.\s[0-9]*|reportdate = $(date +%s)|g" $configfile

#Сортируем файлы в соотвествии с задачей
SortAndSave $homedir$outputfileIP
SortAndSave $homedir$outputfileAddress
SortAndSave $homedir$outputfileErrorsCount

#Приводим даты в удобочитаемый вид
NowDateTime=$(date +"%Y-%m-%d")_$(date +"%H-%M-%S")
reportdate=$(date -d@$reportdate +"%Y-%m-%d")_$(date -d@$reportdate +"%H-%M-%S")

#Отправляем почту
echo "report from $reportdate to $NowDateTime in attachments" | mail -s "report from $reportdate to $NowDateTime" -a outputfileIP -a outputfileAddress -a outputfileErrors -a outputfileErrorsCount $email
