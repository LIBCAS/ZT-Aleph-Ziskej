#!/bin/bash

cd <ziskej/Scripts>

if [[ $1 == "ostry" ]]; then
  outd="../Output"
  urlz="https://ziskej.techlib.cz"
  token=`python3 get_token.py`
  patron=<user MVS>
elif [[ $1 == "test" ]]; then
  outd="../Output-test"
  urlz="https://ziskej-test.techlib.cz"
  token=`python3 get_token-test.py`
  patron=<usr MVS test>
else
  echo "Zadej parametr ostry|test"; exit
fi

[[ ! -d $outd ]] && mkdir $outd
  
                  
email=<email>
urldk=<url DK>
sigla=<sigla DK>
records="$outd/records.json"
log_f="$outd/ziskej.log"
que="$outd/queued.log"
que_tmp="$outd/queued.tmp"
out="$outd/output.xml"





# Ziskani subticketuu a odstraneni uz pouzitych subtiketu z $que

subt=`curl -sX 'GET'   "$urlz:9080/apiaks/v1/libraries/$sigla/roles/dk/subtickets?status=queued"  -H 'accept: application/json' -H "Authorization: Bearer $token"`
subtickets=`echo $subt | grep -Eo '\".{16}\"' | sed  's/\"//g'`

if [[ -f $que ]]; then
  mv $que $que_tmp
  while read -r line;
  do
    [[ "$subtickets" == *"$line"* ]] && echo $line >> $que
  done < $que_tmp
  rm -f $que_tmp
fi


#Ziskani doc_id ze Ziskej podle subticketu
echo > $records
subticket_arr=($subtickets)
for t in ${subticket_arr[@]}
do
  echo `curl -sX 'GET'   "$urlz:9080/apiaks/v1/libraries/$sigla/roles/dk/subtickets/$t"  -H 'accept: application/json'  -H "Authorization: Bearer $token"` | python3 -m json.tool >> $records
done

doc_ids=`jq '"\(.doc_id)+\(.subticket_id)"' $records`
doc_ids=`echo $doc_ids | sed 's/\"//g'`
doc_ids_arr=($doc_ids)



# Ziskat: status vypujcky (On shelf, Requested...), status jednotky (60, 70),  queue
for di in ${doc_ids_arr[@]}
do
  subticket_id=${di#*+}
  doc_id=${di%+*}
  doc_id="KNA01"${doc_id#*-}

  if [[ "$di" == *"null"* ]]; then
    echo "" | mailx -s "Novy pozadavek bez doc_id" $email
    date >> $log_f
    echo "Subticket "$subticket_id >> $log_f
    echo "Zaznam bez doc_id" >> $log_f
    echo >> $log_f
    continue
  fi

  [[ -f "$que" ]] && q=`grep  $subticket_id $que`; [[ $q ]] && continue
  echo $subticket_id >> $que




###Records
  items=`curl -s "$urldk/rest-dlf/record/${doc_id}/items?sublibs=KNAV,KNAVD"  | xmllint --format -`
  rec=`echo  $items | sed  's/<item href="\([^"]*\)"\/>/\1/g'`
  arr=( $rec )
  index=-1; liburl=()
  for  x in ${arr[@]};do
    if [[ $x == *"https"* ]]; then
      index=$((index+1))
      liburl[$index]=$x
    fi
  done


###Record/Items
  for (( i=0; i<${#liburl[@]}; i++ )); do
     [[ "${liburl[$i]}" != *"https:"* ]] && continue
     item=`echo ${liburl[$i]} | sed 's/^.*items\/\(.*\)/\1/'`
     curl -s ${liburl[$i]} | xmllint --format - > $out
     status=`xmllint -xpath "//status/text()" $out` 			#On Shelf, Requested, 13/12/23 09:00..., On Hold
     itemstat=`xmllint -xpath "//z30-item-status-code/text()" $out`	#60, 70


    if [[ $status == "On Shelf" ]]; then
      num[$i]=100
    elif [[ "$status" == *"Requested"* ]] || [[ "$status" == *"On Hold"* ]]; then 
      num[$i]=110
    elif [[ $status =~ ^[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9].* ]]; then
      num[$i]=110
    fi

    if [[ ${itemstat:0:1} == "6" ]]; then
      num[$i]=$((num[$i]+1))
    fi
    num[$i]=${num[$i]}":"$item"0001" # neni potreba dopocitavat nasledujici seq, dopocita se samo

  done



    num1=($(for i in "${num[@]}"; do echo $i; done | sort -n -k1.1,3 -k1.28))
    KNA01=$doc_id
    KNA50=`echo ${num1[0]} | awk -F ':' '{print $2}'`


    note=`curl -sX PUT "$urldk/rest-dlf/patron/"${patron}"/record/"${KNA01}"/items/"${KNA50}"/hold" \
      -d 'post_xml=<?xml version="1.0" encoding="UTF-8"?><hold-request-parameters><pickup-location>KNAV</pickup-location><note-1/></hold-request-parameters>'`
    date >> $log_f
    echo "Subticket "$subticket_id >> $log_f
    echo "Item "$KNA50 >> $log_f
    echo $note >> $log_f
    echo >> $log_f
    if [[ "$note" == *"Action Succeeded"* ]]; then
      subj="Ziskej - Novy pozadavek"
    else
      subj="Ziskej - NEUSPESNY pozadavek"
    fi
    echo -e "$KNA50\n$note" | mailx -s "$subj" $email
done







