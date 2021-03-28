#!/bin/sh

# Checking the spool directory
#SPOOL=/var/spool/diskhogs
SPOOL=/var/spool/WhoEatsDiskSpace
#SPOOL=/mnt/MyMountDisk-or-Partition/_z-my-var/spool/WhoEatsDiskSpace

# First initialyze Database
#sqlite3 \
# "/var/spool/WhoEatsDiskSpace/db" \
# "CREATE TABLE sizes(
#    name           TEXT    NOT NULL,
#    time            TEXT     NOT NULL,
#    size        INT NOT NULL,
#    date_time_hr char(19),
#    size_h varchar(50));"

# If don't do it - Getting error
# Error: no such table: sizes
# Error: no such table: sizes
# Error: no such table: sizes


if [ ! -e "${SPOOL}" ]; then
        mkdir -p "${SPOOL}"
fi
if [ ! -d "${SPOOL}" ]; then
        echo "There are no ${SPOOL} directory" >&2
        exit 1
fi

# if [ -z "${1}" ]; then
#         DIR=.
# else
#         DIR="${1}"
# fi

#DIR=/var

#FILES=$(find "${DIR}" -type f)
#FILES=$(find "${DIR}" -type f -mtime -60 -size +5M)
#FILES=$(find "${DIR}" -type f -mtime -60 -size +10M)
FILES=$(find / \( \( -path "/mnt" -o -path /media -o -path "/proc" -o -path /sys -o -path /run -o -path '*/SomePath*'  \) -prune \) -o   -type f -mtime -90 -size +10M)

# echo $FILES //Debug info - show all found files (by specified criteria)

TIME=$(date +%s)
if [ -z "${TIME}" ]; then
        echo "Can't determine current time" >&2
        exit 1
fi

DATE_TIME_HumanReadable=$(date +'%Y-%m-%d %H:%M:%S')

for FILE in ${FILES}; do
    
    if [ "${FILE}" != "/mnt" ] && [ "${FILE}" != "/media" ] && [ "${FILE}" != "/proc" ] && [ "${FILE}" != "/sys" ] && [ "${FILE}" != "/run" ]; then

        SIZE=$(ls -nl "${FILE}" | awk '{ print $5 }')
        # Where is some problem with files and folders include space in the name
        # ls: cannot access '/home/mylocalusername/.config/vivaldi/Safe': No such file or directory
        # Can't determine size of the /home/mylocalusername/.config/vivaldi/Safe file
        # ls: cannot access '/home/mylocalusername/.config/BraveSoftware/Brave-Browser/Safe': No such file or directory
        # Can't determine size of the /home/mylocalusername/.config/BraveSoftware/Brave-Browser/Safe file
        # $ ls -l /home/mylocalusername/.config/vivaldi/Safe
        # Safe Browsing/                 Safe Browsing Cookies-journal  
        # Safe Browsing Cookies          SafetyTips/        
        if [ -z "${SIZE}" ]; then
                echo $SIZE
                echo "Can't determine size of the ${FILE} file" >&2
                continue
        fi
        SIZE_H=$(ls -nlh ${FILE} | awk '{ print $5 }')

        #sqlite3 "${SPOOL}/db" "INSERT INTO sizes VALUES ('${FILE}', '${TIME}', '${SIZE}');"
        #sqlite3 "${SPOOL}/db" "INSERT INTO sizes VALUES ('${FILE}', '${TIME}', '${SIZE}','${DATE_TIME_HumanReadable}','${SIZE_H}');"        
        if [ ${?} -ne 0 ]; then
                continue
        fi
    else
        echo $FILE
        #echo $(ls -nl ${FILE} | awk '{ print $5 }')
    fi    

done

# for PERIOD in 60 300 600 1800 3600 86400; do

#         TIME_WAS=$((${TIME} - ${PERIOD}))

#         (
#                 echo "*** Since $(date --date="@${TIME_WAS}") (${PERIOD} seconds ago) ***"
#                 sqlite3 \
#                         "${SPOOL}/db" \
#                         "SELECT MAX(size) - MIN(size) AS mm, name
#                                 FROM sizes
#                                 WHERE time >= '${TIME_WAS}'
#                                 GROUP BY name
#                                 ORDER BY mm
#                         ;"
#         ) > "${SPOOL}/report_${PERIOD}"

# done 


# Executing the request

# sqlite3 /var/spool/WhoEatsDiskSpace/db "
sqlite3 "${SPOOL}/db" "
    SELECT MAX(size) - MIN(size) as growing, MAX(size) as max_size, size_h, name, date_time_hr
        FROM sizes
        WHERE            
            size >= 31457280            
        GROUP BY name
        ORDER BY growing DESC, max_size DESC
        LIMIT 15
    ;"


# sqlite> SELECT * FROM sizes WHERE name="/var/log/kern.log" ORDER BY name DESC;
# name               time        size      
# -----------------  ----------  ----------
# /var/log/kern.log  1616261182  599297999 
# /var/log/kern.log  1616261976  623632741

# sqlite3 /var/spool/WhoEatsDiskSpace/db "
#     SELECT MAX(size) - MIN(size) as mm, name
#         FROM sizes
#         WHERE            
#             name like '/var/log/%'
#         GROUP BY name
#         ORDER BY mm DESC
#         LIMIT 15
#     ;"	
 
# Добавляем поле Дата и время в человеко-читаемом формате: 
# $ date +'%Y-%m-%d %H:%M:%S'
# 2021-03-19 17:24:43    
# sqlite3 /var/spool/WhoEatsDiskSpace/db "
# 	ALTER TABLE sizes ADD COLUMN date_time_hr char(19);"

# sqlite3 /var/spool/WhoEatsDiskSpace/db "
# 	ALTER TABLE sizes ADD COLUMN size_h varchar(50);"

# sqlite3 /var/spool/WhoEatsDiskSpace/db "
#     SELECT MAX(size) - MIN(size) as mm, name
#         FROM sizes
#         WHERE            
#             name like '/var/log/%'
#         GROUP BY name
#         ORDER BY mm DESC, size
#         LIMIT 15
#     ;"	
    
# sqlite3 /var/spool/WhoEatsDiskSpace/db "
#     SELECT MAX(size) - MIN(size) as growing, MAX(size) as max_size, name, date_time_hr
#         FROM sizes
#         WHERE            
#             size >= 31457280            
#         GROUP BY name
#         ORDER BY growing DESC, max_size
#         LIMIT 15
#     ;"


# Сколько всего записей в нашей таблице (т.е. сколько файлов с их размерами в разные промежутки времени)
# sqlite> SELECT COUNT(*) FROM sizes;
# COUNT(*)  
# ----------
# 55498 

# Вывести все записи, где размер меньше 5MiB
# sqlite> SELECT * FROM sizes WHERE size<5242880 ORDER BY size DESC;

# sqlite> SELECT COUNT(*) FROM sizes WHERE size<5242880;
# COUNT(*)  
# ----------
# 54138 

# Удаляем все записи, у которых размер (файла) меньше 5MiB
# sqlite> DELETE FROM sizes WHERE size<5242880;

# sqlite> SELECT COUNT(*) FROM sizes;
# COUNT(*)  
# ----------
# 1360 

# НО! Размер файла БД после этого совершенно не измнился!
# И вот почему:
# The size of a SQLite database file does not necessarily shrink when records are deleted. If auto_vacuum is not enabled, it will never shrink unless you perform a vacuum operation on it.

# Выполняем команду Вакуум и вуоля! Размер уменьшиля.
# $ sqlite3 /var/spool/WhoEatsDiskSpace/db 'VACUUM;'

# sqlite> SELECT COUNT(*) FROM sizes WHERE size<10485760;
# COUNT(*)  
# ----------
# 623 

# sqlite> SELECT COUNT(*) FROM sizes;
# COUNT(*)  
# ----------
# 1507

# sqlite> DELETE FROM sizes WHERE size<10485760;

# sqlite> SELECT COUNT(*) FROM sizes;
# COUNT(*)  
# ----------
# 884  

# sqlite> SELECT * FROM sizes WHERE name="/var/log/kern.log" ORDER BY time DESC;
# name               time        size        date_time_hr         size_h    
# -----------------  ----------  ----------  -------------------  ----------
# /var/log/kern.log  1616272175  52359427    2021-03-21 00:29:35  50M       
# /var/log/kern.log  1616271649  36514230    2021-03-21 00:20:49  35M       
# /var/log/kern.log  1616269876  859331078   2021-03-20 23:51:16  820M      
# /var/log/kern.log  1616268982  842028068   2021-03-20 23:36:22  804M      
# /var/log/kern.log  1616267707  801739675   2021-03-20 23:15:07            
# /var/log/kern.log  1616266224  750388297   2021-03-20 22:50:24            
# /var/log/kern.log  1616265331  723543791                                  
# /var/log/kern.log  1616261976  623632741                                  
# /var/log/kern.log  1616261182  599297999

# sqlite> .schema sizes
# CREATE TABLE sizes(
#    name           TEXT    NOT NULL,
#    time            TEXT     NOT NULL,
#    size        INT NOT NULL
# , date_time_hr char(19), size_h varchar(50));

# .mode line
# .mode column
# .headers on
# .width 2 8 8    

#References:
# https://gist.github.com/melnik13/7ad33c57aa33742b9854
# https://serverfault.com/questions/332948/how-to-find-growing-files-inside-a-linux-system
# https://bitbucket.org/bastian_mm/diskdelta/src/master/
# https://bitbucket.org/bastian_mm/diskdelta/src/master/diskdelta-query
# https://bitbucket.org/bastian_mm/diskdelta/src/master/diskdelta-sample

