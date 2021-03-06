#==============================================================================#
# AWSSDB/test/runtests.jl
#
# Copyright Sam O'Connor 2016 - All rights reserved
#==============================================================================#


using AWSSDB
using Base.Test

AWSCore.set_debug_level(1)


#-------------------------------------------------------------------------------
# Load credentials...
#-------------------------------------------------------------------------------

aws = AWSCore.aws_config(region="ap-southeast-2")



#-------------------------------------------------------------------------------
# SDB tests
#-------------------------------------------------------------------------------

db = "aws_sdb_jl_test_domain"
simpledb = SimpleDB(aws, db)

if db in sdb_list_domains(aws)
    sdb_delete_domain(aws, db)
    while db in sdb_list_domains(aws)
        println("Waiting for delete...")
        sleep(1)
    end
end

sdb_create_domain(aws, db)

while !(db in sdb_list_domains(aws))
    println("Waiting for create...")
    sleep(1)
end

data = Dict("key1" => Pair["a1" => "1"],
            "key2" => Pair["a1" => "21", "a2" => "22"],
            "key3" => Pair["a1" => "31", "a2" => "32", "a3" => "33"])

for (k, a) in data
    simpledb[k] = a
end

sleep(1)
while length(collect(sdb_select(aws, "select itemName() from $db"))) < 3
    println("Waiting for put...")
    sleep(1)
end

@test Dict(sdb_get(aws, db, "key1")) == Dict(data["key1"])
@test Dict(sdb_get(aws, db, "key2")) == Dict(data["key2"])
@test Dict(sdb_get(aws, db, "key3")) == Dict(data["key3"])

@test Dict(simpledb["key1"]) == Dict(data["key1"])
@test Dict(simpledb["key2"]) == Dict(data["key2"])
@test Dict(simpledb["key3"]) == Dict(data["key3"])

sdb_put(aws, db, "key1", Pair["a1" => 2], replace=false)

sleep(1)
while length(Dict(sdb_get(aws, db, "key1"))["a1"]) < 2
    println("Waiting for put...")
    sleep(1)
end

@test sdb_get(aws, db, "key1") == Pair["a1" => ["1", "2"]]


@test Dict(sdb_select(aws, "select `a1` from $db")) ==
    Dict("key1" => Pair["a1" => ["1", "2"]],
         "key2" => Pair["a1" => "21"],
         "key3" => Pair["a1" => "31"])

@test Dict(sdb_select(aws, db, ["a1"])) ==
    Dict("key1" => Pair["a1" => ["1", "2"]],
         "key2" => Pair["a1" => "21"],
         "key3" => Pair["a1" => "31"])

@test Dict(sdb_select(aws, db, ["a1", "a2"])) ==
    Dict("key1" => Pair["a1" => ["1", "2"], "a2" => ""],
         "key2" => Pair["a1" => "21", "a2" => "22"],
         "key3" => Pair["a1" => "31", "a2" => "32"])


sdb_delete_item(aws, db, "key1")
sdb_delete_item(aws, db, "key2")
sdb_delete_item(aws, db, "key3")

while length(collect(sdb_select(aws, "select itemName() from $db"))) > 0
    println("Waiting for delete...")
    sleep(1)
end


#==============================================================================#
# End of file.
#==============================================================================#
