#!/bin/bash

#prerequisites
#sudo apt install parallel
#sudo apt install jq
#sudo apt install subfinder

#domain_name
read -p "Please enter the domain name : " domain
echo "1 . Active Enumaration"
echo "2 . Active Enumeration - Parallel"
echo "3 . Passive Enumeration"
echo "4 . Complete Enumeration"
read -p "Select your option : " option

#empty the output files
#replace /home/kali?desktop with your directory
> "/home/kali/Desktop/act_subdomains.txt"
> "/home/kali/Desktop/pas_subdomains.txt"
> "/home/kali/Desktop/final_subdomains.txt"
> "/home/kali/Desktop/temp.txt"

#used wordlist
#https://github.com/theMiddleBlue/DNSenum/blob/master/wordlist/subdomains-top1mil-20000.txt
wordlist="/home/kali/Desktop/wordlist_subdomains.txt"


passive_subdomains(){
    
    echo -e "\nFinding subdomains from subfinder...\n"
    subfinder -d $domain | tee -a "/home/kali/Desktop/temp.txt"
    
    echo -e "\nFinding subdomains from crt.sh...\n"
    curl -s "https://crt.sh/?q=${domain}&output=json" | jq -r '.[].name_value' | tee -a "/home/kali/Desktop/temp.txt"    
    
    echo -e "\n\n\nRemoving duplicates...\n\n"
    cat "/home/kali/Desktop/temp.txt" | sort | uniq > "/home/kali/Desktop/pas_subdomains.txt"
    
    echo -e "\n\nCompleted !"
    echo "Total subdomains - passive enumeration"
    cat "/home/kali/Desktop/pas_subdomains.txt" | wc -l
    echo -e "\n" 	
    
}
export -f passive_subdomains



active_subdomains(){

for sub in $(cat "$wordlist");do
	trydomain="https://${sub}.${domain}"
	response_code=$(curl -i -o /dev/null -s -w "%{http_code}" "$trydomain")	
	if [ "$response_code" -ne 000 ];then
	echo "$trydomain  -  $response_code" >> "/home/kali/Desktop/act_subdomains.txt"
	echo "$trydomain  -  $response_code"
	fi
done	

}
export -f active_subdomains




active_subdomains_parallel(){
   
   local sub="$1"
   local trydomain="${sub}.${domain}"	
   local response_code=$(curl -i -o /dev/null -s -w "%{http_code}" "$trydomain")
	if [ "$response_code" -ne 000 ];then
	echo "$trydomain" >> "/home/kali/Desktop/act_subdomains.txt"
	echo "$trydomain"
	fi

}
export -f active_subdomains_parallel



find_all_subdomains(){

   echo -e "\n\nFinding all subdomains...\n\n" 
   		
   passive_subdomains
   
   echo -e "\nStarting Active Enumeration..."
   cat "$wordlist" | parallel -j 40 active_subdomains_parallel
   
   echo -e "\nChecking for duplicates...\n"
   
   cat "/home/kali/Desktop/act_subdomains.txt" "/home/kali/Desktop/pas_subdomains.txt" | sort | uniq | tee -a "/home/kali/Desktop/final_subdomains.txt"
   
   echo -e "\nFinalising...\n"
   
   echo "Total subdomains - FINAL"
    cat "/home/kali/Desktop/final_subdomains.txt" | wc -l
   
   echo -e "\n\nDone!\n\n"
   
}
export -f find_all_subdomains




export domain



#call functions with menu options


case $option in
   1) 
   	active_subdomains
   	;;
   2)   
   	cat "$wordlist" | parallel -j 40 active_subdomains_parallel
   	;;
   3) 
   	passive_subdomains
   	;;	
   4)	
   	find_all_subdomains
   	;;	
   *)    	
   	echo "Please enter a valid option!"
   	exit
   	;;
esac   		
   	 	
exit
