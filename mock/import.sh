#!/usr/bin/env bash
# Copyright 2022 Meta Mind AB
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


sleep 5
echo -n "Waiting for local test db"
while ! mongo --eval 'db.runCommand("ping").ok' localdb:27017/sme-search --quiet >/dev/null ; do
    echo -n "."
    sleep 1
done
echo ""
echo "Ready!"

mongoimport --host=localdb --username=smearch --password=secret --authenticationDatabase=sme-search --jsonArray --collection=aggregatedSector --db=sme-search --drop --file=/importer/aggregatedSector.json
mongoimport --host=localdb --username=smearch --password=secret --authenticationDatabase=sme-search --jsonArray --collection=aggregatedSector_v3 --db=sme-search --drop --file=/importer/aggregatedSector.json

mongo --username=smearch --password=secret --authenticationDatabase=sme-search --eval 'db.aggregatedSector.createIndex( { "isic": 1, "region": 1 }, { "unique": true } )' localdb:27017/sme-search
mongo --username=smearch --password=secret --authenticationDatabase=sme-search --eval 'db.aggregatedSector_v3.createIndex( { "isic": 1, "region": 1 }, { "unique": true } )' localdb:27017/sme-search
echo "Done!"

if [ "${PREVENT_EXIT:-false}" = "true" ]; then
    echo "Preventing exit by signaling healthy state"
    while true; do nc -l -p 80 ; done
fi
