
db.createCollection("items", {capped:false})
db.createCollection("orders", {capped:false})
db.createCollection("customers", {capped:false})

db.items.insertMany([
    {"category": "Smartwatch", "model":"Mi Band 3", "producer" : "Xiaomi", "price": 20},
    {"category": "Laptop", "model":"Uehk737", "producer" : "Samsung", "price": 1000},
    {"category": "Smartweight", "model":"Body Scale 2", "producer" : "Xiaomi", "price": 100},
    {"category": "Phone", "model":"Galaxy A52", "producer" : "Samsung", "price": 600},
    {"category": "Phone", "model":"iPhone 6", "producer" : "Apple", "price": 600},
    {"category": "TV", "model":"LED 3D 300", "producer" : "Samsung", "price": 2000}
])



db.orders.insertMany([
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
    {"order_number": 3003, "date": ISODate("2021-05-16"), "total_sum": 100, 
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
    {out : "item_per_producer"}
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
        out : "sum_per_customer_2021_04_13",
        query : {date : {$gte: new Date("2021-04-13")}}
    }
)

var mapOrdersSum = function(){
    emit(this._id, this.total_sum)
}

var reduceAvg = function (key, countObjVals){
    reducedVal = { count: 0, qty: 0 };
    for (var idx = 0; idx < countObjVals.length; idx++) {
        reducedVal.count += countObjVals[idx].count;
        reducedVal.qty += countObjVals[idx].qty;
    }
    return reducedVal.count/reduceVal.qty;
}

db.orders.mapReduce(
    mapOrdersSum,
    reduceAvg,
    {out : "avg_sum_orders"}
)

db.orders.mapReduce(
    mapCustomerOrderSum,
    reduceAvg,
    {out : "avg_sum_per_customer"}
)

var flatMapItem = function(){
    for (var idx = 0; idx < this.order_items_id.length; idx++) {
        var key = this.order_items_id[idx].model;
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
        var key = this.order_items_id[idx].model;
        emit(key, this.customer.name);
    }
}

var reduceToList = function(key, values){
    return values
}