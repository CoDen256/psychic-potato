
db.createCollection("items", {capped:false})
db.createCollection("orders", {capped:false})

db.items.insertMany([
    {"category": "Smartwatch", "model":"Mi Band 3", "producer" : "Xiaomi", "price": 20},
    {"category": "Laptop", "model":"Uehk737", "producer" : "Samsung", "price": 1000},
    {"category": "Smartweight", "model":"Body Scale 2", "producer" : "Xiaomi", "price": 100},
    {"category": "Phone", "model":"Galaxy A52", "producer" : "Samsung", "price": 600},
    {"category": "Phone", "model":"iPhone 6", "producer" : "Apple", "price": 600},
    {"category": "TV", "model":"LED 3D 300", "producer" : "Samsung", "price": 2000}
])


db.orders.insertMany([
    // "61ba5c214f2a97bda1f918ec"
    {"order_number": 3000, "date": ISODate("2021-04-13"), "total_sum": 700.7, 
        "customer": {"name": "Andrii", "surname": "Rodionov", "phones": [9876543, 1234567], "address": "PTI, Peremohy 37, Kyiv, UA"},
        "payment" : {"card_owner" :"Andrii Rodionov", "cardId": 12345678},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918d7")},
                            {"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918d8")}]
    },
    {"order_number": 3001, "date": ISODate("2021-04-11"), "total_sum": 1750.7, 
        "customer": {"name": "John", "surname": "Doe", "phones": [0152221834], "address": "Somestree, 13, Kyiv, UA"},
        "payment" : {"card_owner" :"John Doe", "cardId": 123839847},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918db")},
                            {"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918d9")},
                            {"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918dc")}
                            ]
    },
    {"order_number": 3002, "date": ISODate("2021-05-15"), "total_sum": 7365, 
        "customer": {"name": "Erika", "surname": "Burg", "phones": [3015222134], "address": "Strasse, 38a, Kyiv, UA"},
        "payment" : {"card_owner" :"Peter Burg", "cardId": 2846857},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918db")},
                            {"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918d8")}
                            ]
    },
    {"order_number": 3003, "date": ISODate("2021-05-15"), "total_sum": 100, 
        "customer": {"name": "Erika", "surname": "Burg", "phones": [3015222134], "address": "Strasse, 38a, Kyiv, UA"},
        "payment" : {"card_owner" :"Peter Burg", "cardId": 2846857},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")},
                            {"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918d8")},
                            ]
    },
    {"order_number": 3004, "date": ISODate("2021-05-16"), "total_sum": 100, 
    "customer": {"name": "Erika", "surname": "Burg", "phones": [3015222134], "address": "Strasse, 38a, Kyiv, UA"},
    "payment" : {"card_owner" :"Peter Burg", "cardId": 2846857},
    "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")},
                        {"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918d8")},
                        ]
}

])

var mapProducerItems = function() {
    emit(this.producer, 1);
};

var reduceSum = function (key, values){
    return Array.sum(values);
};


db.items.mapReduce(
    mapProducerItems,
    reduceSum,
    {out : "items_per_producer"}
)

var mapProducerPrices = function() {
    emit(this.producer, this.price);
};

db.items.mapReduce(
    mapProducerPrices,
    reduceSum,
    {out : "sum_per_producer"}
)


var mapCustomerOrderSum = function(){
    emit(this.customer.name, this.total_sum)
}


db.orders.mapReduce(
    mapCustomerOrderSum,
    reduceSum,
    {out : "sum_per_customer"}
)

db.orders.mapReduce(
    mapCustomerOrderSum,
    reduceSum,
    {
        out : "sum_per_customer_before",
        query : {date : {$lt: new Date("2021-05-16")}}
    }
)

var mapOrdersSum = function(){
    emit("count", {sum: this.total_sum, count: 1})
}

var reduceAvg = function (key, values){
    reducedVal = { sum: 0, count: 0 };
    for (var idx = 0; idx < values.length; idx++) {
        reducedVal.sum += values[idx].sum;
        reducedVal.count += values[idx].count;
    }
    return reducedVal;
}

var finalizeAvg = function (key, reducedVal){
    return reducedVal.sum/reducedVal.count;
}

db.orders.mapReduce(
    mapOrdersSum,
    reduceAvg,
    {
        out : "avg_sum_orders",
        finalize: finalizeAvg
    }
)

var mapCustomerOrderSumWithCount = function(){
    emit(this.customer.name, {sum: this.total_sum, count: 1})
}

db.orders.mapReduce(
    mapCustomerOrderSumWithCount,
    reduceAvg,
    {
        out : "avg_sum_orders_per_customer",
        finalize: finalizeAvg
    }
)

var flatMapItem = function(){
    for (var idx = 0; idx < this.order_items_id.length; idx++) {
        var key = this.order_items_id[idx]["$id"];
        emit(key, 1);
     }
}

db.orders.mapReduce(
    flatMapItem,
    reduceSum,
    {out : "item_ordered_times"}
)


var mapItemCustomer = function(){
    for (var idx = 0; idx < this.order_items_id.length; idx++) {
        var key = this.order_items_id[idx]["$id"];
        emit(key, this.customer.name);
    }
}

var reduceToSet = function(key, customers){
    return [...new Set(customers)];
}

db.orders.mapReduce(
    mapItemCustomer,
    reduceToSet,
    {out : "item_by_customers_unique"}
)
db.item_by_customers_unique.find()


var mapItemCustomerCount= function(){
    for (var idx = 0; idx < this.order_items_id.length; idx++) {
        var key = this.order_items_id[idx]["$id"];
        emit({item: key, name:this.customer.name}, 1);
    }
}

db.orders.mapReduce(
    mapItemCustomerCount,
    reduceSum,
    {out : "item_by_customers"}
)
db.item_by_customers.find()

var mapItemByCustomer = function (){
    emit(this["_id"].item, this["_id"].name)
}

var reduceToList = function(key, customers){
    return customers;
}

db.item_by_customers.mapReduce(
    mapItemByCustomer,
    reduceToList,
    {
        out : "item_by_customers_gt_1",
        query : {value : {$gt:1}}
    }
)
db.item_by_customers_gt_1.find()

db.item_by_customers.mapReduce(
    mapItemByCustomer,
    reduceToList,
    {
        out : "item_by_customers_gt_2",
        query : {value : {$gt:2}}
    }
)
db.item_by_customers_gt_2.find()


// var mapSortingByPopularity = function() {
//     emit(this.value, this.value)
// }

// db.item_ordered_times.mapReduce(
//     mapSortingByPopularity,
//     reduceToList,
//     {out : "items_by_popularity"}
// )

// db.items_by_popularity.find()

db.sum_per_customer_before.find()

db.orders.insertOne({
    "order_number": 3005, "date": ISODate("2021-05-17"), "total_sum": 9999, 
        "customer": {"name": "Andrii", "surname": "Rodionov", "phones": [9876543, 1234567], "address": "PTI, Peremohy 37, Kyiv, UA"},
        "payment" : {"card_owner" :"Andrii Rodionov", "cardId": 12345678},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")}]
})

db.orders.mapReduce(
    mapCustomerOrderSum,
    reduceSum,
    {
        out : {reduce: "sum_per_customer_before"},
        query : {date : {$gt: new Date("2021-05-16")}}
    }
)

db.sum_per_customer_before.find()


db.orders.insertMany([{
    "order_number": 3006, "date": ISODate("2020-05-12"), "total_sum": 9999, 
        "customer": {"name": "Andrii", "surname": "Rodionov", "phones": [9876543, 1234567], "address": "PTI, Peremohy 37, Kyiv, UA"},
        "payment" : {"card_owner" :"Andrii Rodionov", "cardId": 12345678},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")}]
    },
    {"order_number": 3007, "date": ISODate("2020-04-12"), "total_sum": 9999, 
        "customer": {"name": "Andrii", "surname": "Rodionov", "phones": [9876543, 1234567], "address": "PTI, Peremohy 37, Kyiv, UA"},
        "payment" : {"card_owner" :"Andrii Rodionov", "cardId": 12345678},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")}]
    },
    {"order_number": 3007, "date": ISODate("2021-04-12"), "total_sum": 9999, 
        "customer": {"name": "Andrii", "surname": "Rodionov", "phones": [9876543, 1234567], "address": "PTI, Peremohy 37, Kyiv, UA"},
        "payment" : {"card_owner" :"Andrii Rodionov", "cardId": 12345678},
        "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")}]
    },


    {"order_number": 3008, "date": ISODate("2020-05-16"), "total_sum": 100, 
    "customer": {"name": "Erika", "surname": "Burg", "phones": [3015222134], "address": "Strasse, 38a, Kyiv, UA"},
    "payment" : {"card_owner" :"Peter Burg", "cardId": 2846857},
    "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")},
                        ]
    },
    {"order_number": 3009, "date": ISODate("2021-04-01"), "total_sum": 100, 
    "customer": {"name": "Erika", "surname": "Burg", "phones": [3015222134], "address": "Strasse, 38a, Kyiv, UA"},
    "payment" : {"card_owner" :"Peter Burg", "cardId": 2846857},
    "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")},
                        ]
                    },
                    {"order_number": 3009, "date": ISODate("2021-04-16"), "total_sum": 100, 
                    "customer": {"name": "Erika", "surname": "Burg", "phones": [3015222134], "address": "Strasse, 38a, Kyiv, UA"},
                    "payment" : {"card_owner" :"Peter Burg", "cardId": 2846857},
                    "order_items_id" : [{"$ref" : "items", "$id" : ObjectId("61ba1c964f2a97bda1f918da")},
                            
                                        ]
                                    }                
])



var mapFullInfo = function(){
    emit(
        {name: this.customer.name, month:this.date.getMonth() + 1}, 
    {
        name : this.customer.name,
        year: this.date.getFullYear(),
        month: this.date.getMonth() + 1,
        amount: this.date.getFullYear() == 2021 ? this.total_sum : 0,
        prev_year_amount: this.date.getFullYear() == 2020 ? this.total_sum : 0
    })
}

var reduceFullInfo = function(key, values){
    var reducedObj = {
        name : key.name,
        year: 2021,
        month: key.month,
        amount: 0,
        prev_year_amount: 0

    }
    for (var idx = 0; idx < values.length; idx++) {
        var obj = values[idx];
        if (parseInt(obj.year) == 2021){
            reducedObj.amount += obj.amount;
        }
        if (parseInt(obj.year) == 2020){
            reducedObj.prev_year_amount += obj.prev_year_amount;
        }
    }
    return reducedObj;
}

var finalizeFullInfo = function (key, reducedObj){
    reducedObj.diff = reducedObj.amount - reducedObj.prev_year_amount;
    return reducedObj;
}

db.orders.mapReduce(
    mapFullInfo,
    reduceFullInfo,
    {
        out : "full_info",
        finalize: finalizeFullInfo
    }
)
db.full_info.find()

var emit = function(key, value) {
    print("emit");
    print(key.name);
    print(key.mon);
    print(value.name);
    print(value.year);
    print(value.mon);
    print(value.amount);
    print(value.prev_year_amount);
}
