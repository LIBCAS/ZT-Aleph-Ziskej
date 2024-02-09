# ZT-Aleph-Ziskej
## Propojení služby Získej a systému Aleph

Úkolem skriptu je automatizovat vznik požadavku ze služby Získej do Alephu. Jde tedy o to, aby knihovníci nemuseli průběžně kontrolovat Získej, následně zjišťovat o jakou jednotku se jedná a potom ručně zadávat požadavek do databáze Alephu dožádané knihovny. 

Výpůjčka je realizována bash skriptem. Skript se v určitých intervalech dotazuje API Získej, zda byl vytvořen požadavek na publikaci z fondu DK. Pokud ano, skript podle přijatého doc_id (SYSNO) vybere příslušnou jednotku. Tu předá přes API Alephu tak, aby v systému vznikl požadavek, který se automaticky vytiskne v depozitáři a do MVS pak dorazí rovnou do ruky kniha.  Dále už bude MVS postupovat ve webovém rozhraní ziskej.cz.



Řeší se:

Pokud ŽK zadá požadavek  přímo přes portál Získej, nikoliv přes Knihovny.cz, pak požadavek přijde  bez doc_id. Pak není v záznamu Získej jednoznačný identifikátor.

Je-li  zadán požadavek na publikaci, která je o více dílech, nelze přes API Alephu získat jednoznačnou identifikaci konkrétních dílů. Informace je nestrukturovaně uložena v poli pro poznámky příslušné jednotky.

