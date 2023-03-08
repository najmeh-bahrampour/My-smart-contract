pragma solidity 0.8.7;

contract VMI{

//Entities Adresses
address public manufacture=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
address public govenrnment=0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
address  public distributer=0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
address public  colectoradress=0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
address [] public retailoradress;
address adres_time_contract;

//Distance matrix between producer and retailer
uint [] public distance_matrix;
uint [4] vehicle_capacity=[70,90,100,150];
uint public number_type_product=4;
//Fixed penalty fee for each unit of difference between the shipment received and sent by the distributorه
uint penalty_dif=1000 ;
//Carriage cost of any type of vehicle
uint [] public price_transshipment_array_toman=[8000,9000,11000,15000 ];
//4 type of vehicle
uint [4] public price_transshipment_array;

mapping(address=>uint) public balance_map;
mapping(uint=>vehicle_struct) public vehicle_map;
mapping(address=>uint) public all_requested_retailors_score;
//address and register of costumers
mapping(uint=>address) public costumeresmap;
mapping(uint=>costumers_struct) public costumers_map;
mapping(address=>uint[4]) retailor_inv_list_map;
mapping(address=>uint[4]) retailors_reserved_inventory_map;
mapping(uint=>uint) prdct_price_map;
mapping (uint=>mapping(uint=>uint [4])) public all_demand_map;
//mapping week to retailors_id to sum of product
mapping (uint=>mapping(uint=>uint[4])) sum_toretailo_map;
mapping(uint=>uint) cost_shipment_status_map;
mapping(uint=>cargo_to_retailors_status) public cargo_retailors_status_map;
mapping(uint=>uint) public cargodestinationmap;
mapping (uint=>uint [][4]) cargo_barcod_map;
mapping(uint=>uint[4]) cargo_prdct_number_map;
//Let me write a map for the relationship between the vehicle and the cargo
mapping(uint=>uint) assignvehiclemap;
mapping(uint=>uint[]) diferencemap;
mapping(uint=>bool) recived_cargo_map;
mapping(uint=>uint[4])recived_cargo_prdct_num_map;
// We map each shipment number to its cost, if there is a cost
mapping (uint=>uint) cargo_cost_map;
// We map each cargo number to its fine, if it is a fine (this means that it is a fine)
mapping (uint=>uint) cargo_penalty_map;
mapping(address=>bool) Product_delivery_status_map;
mapping(address=>uint[]) colected_product_retailor;



enum vehicle_status {send,ready,inrout,free} 
enum productinuseCustumer{Safe,shouldchange,critical}
enum order_of_costumer{ordered,reserved,delivered}
enum status_of_custumer{new_registered,Old}
enum cargo_to_retailors_status {ready_for_shipment,loading,in_shipment,deliverd_retailors}

struct vehicle_struct{
    address v_address;
    uint v_type;//should be from 0 to 3 beacause we have 4 type
    vehicle_status  v_status;   
}

struct costumers_struct{
  uint _costumerid;
  productinuseCustumer Prdct_status_Custume;
  order_of_costumer order_status_costumer;
  status_of_custumer status_costumer;
  uint product_type;
  uint product_barcode;
  uint time_order;//Requested Delivery time
  uint time_delivered;//Real Delivery time
  address asigned_retailo;
  uint asigned_retailor_number;
  uint delayday_manufacture;
  bool det_share_re_cu_manu;
}



function aaa_first_balance_maping() public{
    balance_map[manufacture]=10000* 10000000000000000000;
    balance_map[distributer]=1000* 1000000000000000000;
    balance_map[govenrnment]=10000* 1000000000000000000;
     balance_map[colectoradress]=address(colectoradress).balance;
}

function aaaab_vehicle_map(uint vehicle_id,address vehicle_adress,uint v_type)
public onlydistributer returns(string memory){
require(v_type<=3);
 vehicle_map[vehicle_id]. v_address=vehicle_adress;
 vehicle_map[vehicle_id].v_type=v_type;
 vehicle_map[vehicle_id].v_status=vehicle_status.free;
 return "Vehicle is registered";
}
  
function b_calculate_score(uint physical_facility,
uint validation,uint potential_costumer,address ret_adrs) 
onlymanufacture public  returns(uint){
// All points are entered from hundred
   uint score;
   score=((physical_facility+validation+potential_costumer)*100/300);
   all_requested_retailors_score[ret_adrs]=score;
   return score;
 }


 function bb_push_retailor_address_distance(address re_adrs,
 uint distance,uint [] memory _inventorylist)onlymanufacture public returns(uint){
     require(all_requested_retailors_score[re_adrs]>50);
        retailoradress.push(re_adrs);
        distance_matrix.push(distance);
         balance_map[re_adrs]=address(re_adrs).balance;
         for (uint i=0; i<number_type_product; i++){
         retailor_inv_list_map[re_adrs][i]=_inventorylist[i];
    }
    uint id_of_retailors;
    for (uint j=0; j<number_type_product; j++){
                retailors_reserved_inventory_map[re_adrs][j]=0;
        }
        return id_of_retailors=retailoradress.length-1;
}



uint32 cus_id=1
;
//Each Costumer must register in contract
function bb_register_customer(address _cusadrs,bool _isnew,bool custumer_sign) public
 returns( string memory msgto)  {
require(custumer_sign=true);
   if (_isnew==true){
     costumeresmap[cus_id]=_cusadrs;
     costumers_map[cus_id]._costumerid=cus_id;
     costumers_map[cus_id].status_costumer=status_of_custumer.new_registered;
     balance_map[_cusadrs]=address(_cusadrs).balance; 
     cus_id=cus_id+1;
     return "Registration Is Done";
}
}

// Map each type of product to its price
function c_product_price_map(uint _ptype,uint _price) public  onlymanufacture
 returns(uint) {
   //insert price in doller
   uint p=(_price* 1000000000000000000/1600); 
   return prdct_price_map[_ptype]=p ;
}

function cb_price_transship_in_wei() public{
   for(uint i=0;i<price_transshipment_array_toman.length;i++){
           uint a=(price_transshipment_array_toman[i]*1000000000000000000)/1600;
          price_transshipment_array[i]=a;
   }
}


//writing modifires

modifier  onlymanufacture(){ //only manufacture can do it
        require(manufacture == msg.sender); 
        _;
    }
modifier  onlydistributer(){ //only manufacture can do it
        require( msg.sender==distributer); 
        _;
    }
modifier  onlyretailors(uint retailorid) { //only retailor can do it
   require(msg.sender==retailoradress[retailorid]);
_;
}
modifier  onlycollector() { //only collector can do it
   require(msg.sender==colectoradress);
_;}
modifier  onlycostumers(uint id) { //only retailor can do it
    require(msg.sender==costumeresmap[id]);
       _;    
}


//events
//در این قسمت ایونت ها رو مینویسم 
//تمام ایونتا رو مذارم ببینم کدوما به دردم میخوره بعد اضافه میکنم
event cargoReadyforshipment(address manufacturer, uint[4] product_num,uint typvehicle);
event vehile_send_forshipment(address vicle_adress,uint vehicle_id);
event location_continer(string msg);
//Consignment status ready to send to the retailer


// writing main function 

///////////////////////


function cbb_orders_ret_week(uint [4] memory product_demand, uint _ret_id, uint week_num )
 public onlymanufacture {
   for(uint i=0;i<4;i++){
       all_demand_map[week_num][_ret_id][i]=product_demand[i];
       if(retailor_inv_list_map[retailoradress[_ret_id]][i]-
       all_demand_map[week_num][_ret_id][i]>0)/* 0is rop*/{
         sum_toretailo_map[week_num][_ret_id][i]=0;}
         else{
           sum_toretailo_map[week_num][_ret_id][i]=
           all_demand_map[week_num][_ret_id][i]-
           retailor_inv_list_map[retailoradress[_ret_id]][i];
         }
    }  
}



function cc_request_Container(uint [4] memory product_num,uint _vehicletype, uint ret_des,
uint cargo_num) public onlymanufacture {
  for (uint i=0;i<4;i++){
     cargo_prdct_number_map[cargo_num][i]=product_num[i];
  }
    uint vtype=_vehicletype;
    cargodestinationmap[cargo_num]=ret_des;    
    cargo_retailors_status_map[cargo_num]=cargo_to_retailors_status.ready_for_shipment;
    cost_shipment_status_map[cargo_num]=0;
    emit cargoReadyforshipment(msg.sender,cargo_prdct_number_map[cargo_num],vtype);
}


// The function of assigning the vehicle to the transport direction

function ccc_assign_vehicle(uint vehicleid,uint cargo_num) onlydistributer public  returns(address) {
 require(vehicle_map[vehicleid].v_status==vehicle_status.free);
  uint sum_cargo=0;
 for(uint i=0;i<4;i++){
         sum_cargo=cargo_prdct_number_map[cargo_num][i]+ sum_cargo;
 }
 require(sum_cargo<=vehicle_capacity[vehicle_map[vehicleid].v_type]);
  emit vehile_send_forshipment(vehicle_map[vehicleid].v_address,vehicleid);
// I came here to specify which vehicle the cargo was sent with
  assignvehiclemap[cargo_num]=vehicleid;
  vehicle_map[vehicleid].v_status=vehicle_status.send;
  return vehicle_map[vehicleid].v_address;
}


//Entering the vehicle to the manufacturer for loading
function cccc_vehicle_ready(uint vehicleid) onlymanufacture public{
    vehicle_map[vehicleid].v_status=vehicle_status.ready;
    emit location_continer("Ready for Loading");
}

// After the end of loading and the start of the operation, the position is also updated by the manufacturer
function d_start_shipment(uint vehicleid,uint cargo_num) public  {
    require(assignvehiclemap[cargo_num]==vehicleid) ;
        require(cargo_retailors_status_map[cargo_num] ==
         cargo_to_retailors_status.ready_for_shipment);
        require(vehicle_map[vehicleid].v_status==vehicle_status.ready);
        cargo_retailors_status_map[cargo_num]=cargo_to_retailors_status.loading;             
    }

//The status of the vehicle in transit can also be updated via the following

function dd_vehicle_in_shipment(uint cargo_num,string memory vehicle_location) public{
    uint vehicleid=assignvehiclemap[cargo_num];
    require(cargo_retailors_status_map[cargo_num]==cargo_to_retailors_status.loading);
    vehicle_map[vehicleid].v_status=vehicle_status.inrout;
    cargo_retailors_status_map[cargo_num]=cargo_to_retailors_status.in_shipment; 
    emit location_continer(vehicle_location);
}

//Carrier and cargo status after delivery
function ddd_vehicle_in_destination(uint vehicleid,uint cargo_num,uint id_ret) public
 onlyretailors(id_ret) {
require(cargo_retailors_status_map[cargo_num]==cargo_to_retailors_status.in_shipment);
require( vehicle_map[vehicleid].v_status==vehicle_status.inrout);
vehicle_map[vehicleid].v_status=vehicle_status.free;
emit location_continer("in destination");
cargo_retailors_status_map[cargo_num]=cargo_to_retailors_status.deliverd_retailors;
}


function dddd_check_cargo_Retailors(uint cargo_num,uint [] memory barcodes_dif,
uint retailorid,uint [4] memory Product_type_num) onlyretailors(retailorid) 
  public returns(bool){
require(cargodestinationmap[cargo_num]==retailorid); 
 //update inventory position  
 for(uint i=0;i<number_type_product;i++){
         recived_cargo_prdct_num_map[cargo_num][i]=Product_type_num[i];
         retailor_inv_list_map[msg.sender][i]=Product_type_num[i]+
         retailor_inv_list_map[msg.sender][i];
 }
 // specify diference
  diferencemap[cargo_num]=barcodes_dif;
  if(cargo_prdct_number_map[cargo_num][0]==Product_type_num[0]&&
  cargo_prdct_number_map[cargo_num][1]==Product_type_num[1]&&
  cargo_prdct_number_map[cargo_num][2]==Product_type_num[2]&&
  cargo_prdct_number_map[cargo_num][3]==Product_type_num[3]){
          return recived_cargo_map[cargo_num]=true;
  }
   else{
        return recived_cargo_map[cargo_num]=false;
   } 
}


function e_pay_transshipment_cost(uint cargo_num,uint vehicle_id) public payable
 onlymanufacture  {
  if(cost_shipment_status_map[cargo_num]==0){
     uint cost_shipment=price_transshipment_array[vehicle_map[vehicle_id].v_type]*
     distance_matrix[cargodestinationmap[cargo_num]];
   if (recived_cargo_map[cargo_num]==true){
        cargo_cost_map[cargo_num]=cost_shipment;
        require(balance_map[manufacture]>cargo_cost_map[cargo_num]);
        //پرداخت هزینه حمل
        balance_map[manufacture]=balance_map[manufacture]-cargo_cost_map[cargo_num];
        balance_map[distributer]=balance_map[distributer]+cargo_cost_map[cargo_num];
        cost_shipment_status_map[cargo_num]=1;  
    } 
    else{
     uint dif_num=0;
     for (uint i=0;i<4;i++){
         if(cargo_prdct_number_map[cargo_num][i]-recived_cargo_prdct_num_map[cargo_num][i]>0){
           dif_num=cargo_prdct_number_map[cargo_num][i]-recived_cargo_prdct_num_map[cargo_num][i]+
           dif_num;
         }    
     }
      uint penalty_diference=dif_num*penalty_dif;
      if(cost_shipment>penalty_diference){
        cargo_cost_map[cargo_num]=cost_shipment-penalty_diference;
        require(balance_map[manufacture]>cargo_cost_map[cargo_num]);
        balance_map[manufacture]=balance_map[manufacture]-cargo_cost_map[cargo_num];
        balance_map[distributer]=balance_map[distributer]+cargo_cost_map[cargo_num];
        cost_shipment_status_map[cargo_num]=1; 
      }
      else if(cost_shipment<penalty_diference){
        cargo_penalty_map[cargo_num]=penalty_diference-cost_shipment;
        require(balance_map[distributer]>cargo_penalty_map[cargo_num]);
        balance_map[manufacture]=balance_map[manufacture]+ cargo_penalty_map[cargo_num];
        balance_map[distributer]=balance_map[distributer]- cargo_penalty_map[cargo_num];
        cost_shipment_status_map[cargo_num]=2;
      }
      else if(cost_shipment==penalty_diference){
          cost_shipment_status_map[cargo_num]=1;
    }
  }
}
}


//Customer order for retailer
//Whenever the product in use is in the state to be replaced
// It should be announced to the customer that it is the exchange point
//This is in the case that the customer is one of the old customers

function ee_costumer_old_order(bool confirmation_result,uint id) onlycostumers(id) 
public payable{
   address custumer_adress=costumeresmap[id];
   productinuseCustumer product_status;
  product_status=costumers_map[id].Prdct_status_Custume;
   require (product_status==productinuseCustumer.shouldchange||
   product_status==productinuseCustumer.critical);
     require(confirmation_result=true);
       uint p_type=costumers_map[id].product_type;  
         if(balance_map[custumer_adress]>=prdct_price_map[p_type]){
            balance_map[custumer_adress]=balance_map[custumer_adress]- 
            prdct_price_map[p_type];
            balance_map[manufacture]=balance_map[manufacture]+
             prdct_price_map[p_type];
            costumers_map[id].order_status_costumer=order_of_costumer.ordered;
            costumers_map[id].det_share_re_cu_manu=false;
          }
   }



function eee_costumer_new_order(bool confirmation_result,
uint id,uint p_type) onlycostumers(id) public payable{
// Customer's status must be registered in the new state and
// also specify the type of product
   address custumer_adress=costumeresmap[id];
   status_of_custumer  cu_status;
   cu_status=costumers_map[id].status_costumer;
   require(cu_status==status_of_custumer.new_registered);
   require(confirmation_result=true);

//Unlike the previous case, here the type of product is determined by the customer in the first purchase
        costumers_map[id].product_type=p_type;  
      //First, the balance of the customer's account must be more than the price of the product, and if it is more
  //Payment is done and order details are recorded
  // In this case, the type of product must also be determined as an input
      
         if(balance_map[custumer_adress]>=prdct_price_map[p_type]){
            balance_map[custumer_adress]=balance_map[custumer_adress]- prdct_price_map[p_type];
            balance_map[manufacture]=balance_map[manufacture]+ prdct_price_map[p_type];
//After deducting the cost, the customer's order will be placed in the ordered state
           costumers_map[id].order_status_costumer=order_of_costumer.ordered;
           costumers_map[id].det_share_re_cu_manu=false;
          }
  }

//Determine ordering time and delivery time

function ef_insert_adrestime(address cntrct_adr) public onlymanufacture {
        adres_time_contract=cntrct_adr;
}

//Determining the order delivery time by the customer by entering the following 
//data and converting this time to a time stamp

function f_call_toTimestamp_order(uint id,uint16 year, uint8 month, uint8 day,
 uint8 hour, uint8 minute, uint8 second) public returns(uint) {
    
// It must first be checked that the ID belongs to the customer
 require(costumeresmap[id]==msg.sender);
// The order must be in order status
     require(costumers_map[id].order_status_costumer==order_of_costumer.ordered);
      DateTime b=DateTime(adres_time_contract);
      costumers_map[id].time_order=b.toTimestamp(year,month,day,hour,minute,second);
      return costumers_map[id].time_order;
}

function fb_assigning_customer_to_retailer(uint id_cus,uint [] memory cust_dis)public returns(uint)
 /*onlycostumers(id_cus)*/ {
  uint  asigned_ret_num;
  uint mindis=200;
  for(uint i=0;i<retailoradress.length;i++){
    if (cust_dis[i]<=mindis){    
      asigned_ret_num=i;
      mindis=cust_dis[i];
            }
  }  
 costumers_map[id_cus].asigned_retailor_number= asigned_ret_num;    
  return  asigned_ret_num;
}


// Calculate time and delays

//Delivery of the product to the customer by the retailer
//Retailer must be assigned to the customer
// The delivery time must be recorded for the customer to determine the delay

//Calculation and payment to the retailer
//We also have to consider if there was a delay in delivery to the customer, from whom
//If it was from the retailer, we should collect the fine from the retailer
//If the delay in the delivery of the product is due to the retailer's inventory
// In the case of the requested product not being supplied, the fine belongs to the manufacturer
//We have a series of state variables, one of which is the inventory of each retailer
//a percentage paid of the price to the retailer which is actually the retailer's profit


// Checking and blocking the inventory for the customer who has confirmed her order
function ff_reserve_inv_for_customer(uint id_cus)  public onlycostumers(id_cus){
    uint prdct_type=costumers_map[id_cus].product_type;
    costumers_map[id_cus].asigned_retailo=retailoradress[costumers_map[id_cus].asigned_retailor_number];
    address _asigned_retailor=costumers_map[id_cus].asigned_retailo;

//If the status of the customer's order is placed
  if (costumers_map[id_cus].order_status_costumer==order_of_costumer.ordered){

//If the inventory amount for the assigned retailer is positive
//Reserved inventory is removed from the retailer's available inventory
          if (retailor_inv_list_map[ _asigned_retailor][prdct_type-1]>=1){
                  retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]=
                  retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]+1;
                  retailor_inv_list_map[ _asigned_retailor][prdct_type-1]=
                  retailor_inv_list_map[ _asigned_retailor][prdct_type-1]-1;
//The status for the customer is also changed to reserved
                  costumers_map[id_cus].order_status_costumer=order_of_costumer.reserved;
          }
//If the amount of inventory available for the retailer is low
          else if(retailor_inv_list_map[ _asigned_retailor][prdct_type-1]<1&&
          block.timestamp<costumers_map[id_cus].time_order){
                  uint checktime=block.timestamp;
//starts checking the balance from the next day
                  checktime=checktime+86400;
//If the customer's ordering time is less than the current time
                  while (checktime<costumers_map[id_cus].time_order){    
// If the balance is positive, it will be allocated to the customer
                          if  (retailor_inv_list_map[ _asigned_retailor][prdct_type-1]>=1){
                              retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]=
                              retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]+1;
                              retailor_inv_list_map[ _asigned_retailor][prdct_type-1]=
                                retailor_inv_list_map[ _asigned_retailor][prdct_type-1]-1;
                              costumers_map[id_cus].order_status_costumer=order_of_costumer.reserved;

                              costumers_map[id_cus].delayday_manufacture=0;
    
// If the balance is allocated, it will be exited from the  loop                            //و مشتری دچار کمبود نمیشود و کسی متحمل هزینه کمبود نیست
                            break;
                           } 
                           else {
                               checktime=checktime+86400;
                           }
                      }
                    }
                }
           
//If there is no inventory and the time exceeds the time specified by the customer,
// in this case the customer will be justified with shortage and this cost of shortage 
//is related to the manufacturer. In this case, I have to write until the 
//inventory is received and allocated to the customer.

            else if(retailor_inv_list_map[ _asigned_retailor][prdct_type-1]<1
            &&block.timestamp>costumers_map[id_cus].time_order){
                uint checktime=block.timestamp;
                checktime=checktime+86400;
                bool continu=true;
                while (continu==true) {
                        if  (retailor_inv_list_map[ _asigned_retailor][prdct_type-1]>=1){
                            retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]=
                           retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]+1;
                              retailor_inv_list_map[ _asigned_retailor][prdct_type-1]-1;
                               costumers_map[id_cus].order_status_costumer=
                               order_of_costumer.reserved;
                               costumers_map[id_cus].delayday_manufacture=
                               block.timestamp-costumers_map[id_cus].time_order;
                               
                               // In case of allocating inventory, it will be exited from the loop
                           
                            break;
                       }
                       else{
                            checktime=checktime+86400;
                       }

                
            }
     }
  }

//Inventory is blocked for the customer and must be delivered to the customer after being blocked
//And the delivery time should also be specified so that delays can be calculated

//Delivery order to be given to the retailer from the centralized system

function g_build_map_Product_delivery(uint id_cus,bool deliver_order) public onlymanufacture {
  address custumer_adress=costumeresmap[id_cus];
     require(costumers_map[id_cus].order_status_costumer==order_of_costumer.reserved);
      Product_delivery_status_map[custumer_adress]=deliver_order;
}

// Create a array and enter the list of used
// products that are collected from the customer by the retailer

function gg_delivery_customer(uint re_id,uint id_cus,uint barcode_delivered_product)
onlyretailors(re_id) public returns(uint) {
address _asigned_retailor=retailoradress[re_id];
address custumer_adress=costumeresmap[id_cus];
uint prdct_type=costumers_map[id_cus].product_type;

// Check whether the delivery is correct by the assigned retailer
  require(msg.sender==costumers_map[id_cus].asigned_retailo);
//The delivery order must have been issued
  require(Product_delivery_status_map[custumer_adress]==true);
//Must be reserved inventory
   costumers_map[id_cus].time_delivered=block.timestamp;
   if (costumers_map[id_cus].product_barcode==0){
// In this case, the customer does not have a delivery order in advance
      costumers_map[id_cus].product_barcode=barcode_delivered_product;
       costumers_map[id_cus].Prdct_status_Custume=productinuseCustumer.Safe;

      }
      else{

// The used product is delivered and 
//a new one is delivered and the customer's information is updated
              colected_product_retailor[msg.sender].push(costumers_map[id_cus].
              product_barcode);
              costumers_map[id_cus].product_barcode=barcode_delivered_product;
             costumers_map[id_cus].Prdct_status_Custume=productinuseCustumer.Safe;

      }
// It should also be subtracted from the reserved inventory list
     retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]=
     retailors_reserved_inventory_map[_asigned_retailor][prdct_type-1]-1;
     return costumers_map[id_cus].time_delivered;

}



//reading function for interaction 
function hh_read_asginedretailor(uint cu_id) public view returns(address){
       return costumers_map[cu_id].asigned_retailo;
}

function hh_read_product(uint cu_id) public view returns(uint){
       return costumers_map[cu_id].product_type;
}


function hh_read_det_share_re_cu(uint cu_id) public view returns(bool){
       return costumers_map[cu_id].det_share_re_cu_manu;
}

function hh_read_time(uint cu_id) public view returns(uint){
   uint a=costumers_map[cu_id].time_order;
   uint b=costumers_map[cu_id].time_delivered;
   return b-a;
}

function hh_delayday_manufacture(uint cu_id) public view returns(uint){
   return costumers_map[cu_id].delayday_manufacture;
}

function read_price_map(uint productType)  public view returns(uint){
        return prdct_price_map[productType];
}

function read_balancemap(address adrs) public view returns(uint){
        return balance_map[adrs];
}

function updateadd_balance_map(address _adrs,uint plus) public {
               balance_map[_adrs]=balance_map[_adrs]+plus;
}
function updatesub_balance_map(address _adrs,uint sub) public {
               balance_map[_adrs]=balance_map[_adrs]-sub;
}
function update_det_share_re_cu(uint cu_id) public {
        costumers_map[cu_id].det_share_re_cu_manu=true;
}

function read_colected_product_retailor(address re_adrs) public view returns(uint[] memory ){
     return colected_product_retailor[re_adrs];
   
}

function u_delete_colected_retailor(uint re_id )  public {
 address re_adrs=retailoradress[re_id];
        delete colected_product_retailor[re_adrs]; 
}

}



///////////////////////////////////////////////////////////////
contract Sustainable_and_pay{

// amount of penalty per time stamp unit
uint penalty_cost=1 ;//// Penalty for every hour of delay
//Definition of the percentage of the retailer's share of the sales of each product unit
uint percent_of_retailor=20;

//Part related to collection centers and government
mapping(address=>uint []) collected_product_map;
mapping(address=>uint []) collected_product_map_pay_status;
mapping(address=>uint []) collected_product_map_pa_government;
mapping(uint=>uint []) difrence_barcode_map;
uint cost_of_one_colected=200 wei;
address public govenrnment=0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
address public manufacture=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
address public  colectoradress=0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;


uint i_of_difrence_barcode_map=0; 
uint Last_number_paid=0;

VMI public vmi;

    constructor(VMI _adress_vmi) {
        vmi = _adress_vmi;
    }


// Determine the retailer's share
//Calculate and pay the retailer's share

function a_calculate_cost(uint cu_id) onlymanufacture public payable {

 address custumer_adress=vmi.costumeresmap(cu_id);

 address asigned_retail= vmi.hh_read_asginedretailor(cu_id);

 uint productType=vmi.hh_read_product(cu_id);
 require(vmi.hh_read_det_share_re_cu(cu_id)==false);

// First, we calculate the difference between the delivered time
// and the time set by the customer
uint a=vmi.hh_read_time(cu_id);

 uint b=vmi.hh_delayday_manufacture(cu_id);
 uint mohlat_tahvil_yekrooze=24*60*60;
//The amount of delay related to the retailer
 uint c=a-b-mohlat_tahvil_yekrooze;
 uint dp=b+mohlat_tahvil_yekrooze;

//The amount of delay related to the producer
 
//If we assume that the retailer did not deliver to the customer due to a shortage
// until the inventory is secured, then he has one day to calculate the delay in 
//delivery from the time of receipt to the time of delivery to the customer, 
//and if it exceeds this time, he will also suffer. The fine will be delivered.
//If the delay is from the retailer's side, consider a few hours for the
// delivery time so that we can consider this delivery time as floating.
// I assume that the floating time is two hours.

  if (a>2*60*60&&b==0) {
    uint penalty=((a-2*60*60))*penalty_cost;
    uint pay_toretailor;
//Calculation of the amount paid to the// retailer based on the determined percentage minus the fine
     pay_toretailor=((vmi.read_price_map( productType))*percent_of_retailor/100)-penalty;
//Payment to retailer
     if (((vmi.read_price_map( productType))*percent_of_retailor/100)-penalty>0){
       require(vmi.read_balancemap(vmi.manufacture())>=penalty);
        require(vmi.read_balancemap(vmi.manufacture())>=pay_toretailor);


       vmi.updateadd_balance_map(asigned_retail,pay_toretailor);
       vmi.updateadd_balance_map(custumer_adress,penalty);
       vmi.updatesub_balance_map(vmi.manufacture(),penalty+pay_toretailor);
       vmi.update_det_share_re_cu(cu_id);
        }
        else if(penalty-((vmi.read_price_map( productType)*percent_of_retailor)/100)>0){  
           require(vmi.read_balancemap(asigned_retail)>=penalty-((vmi.read_price_map( productType)*percent_of_retailor)/100));
            vmi.updatesub_balance_map(asigned_retail,((vmi.read_price_map( productType)*percent_of_retailor)/100));
        vmi.updateadd_balance_map(custumer_adress,((vmi.read_price_map( productType)*percent_of_retailor)/100));
        }
        
// If the delay is from the producer side
  else if (b>0&&(c<=0)){
     uint _penalty=((a-2*60*60)/(60*60))*penalty_cost;
     uint _pay_toretailor;
//Calculation of the payment amount to the retailer based on the determined percentage
     pay_toretailor=((vmi.read_price_map( productType)*percent_of_retailor)/100);     
//Payment to retailer//Payment to retailer
     require( vmi.read_balancemap(vmi.manufacture())>=penalty+_pay_toretailor);
        vmi.updateadd_balance_map(asigned_retail,_pay_toretailor);
        vmi.updateadd_balance_map(custumer_adress,_penalty);
         vmi.updatesub_balance_map(vmi.manufacture(),pay_toretailor+_penalty);


  }
//If the delay is from both sides, both the manufacturer and the retailer
  else if (b>0&&(c>2*60*60)){
      //سهم جریمه خرده فروش
    uint penalty1=((c-2*60*60)/(60*60))*penalty_cost;
    //سهم جریمه تولید کننده
    uint penalty2=((dp-2*60*60)/(60*60))*penalty_cost;
    uint _pay_toretailor;
//Calculation of the payment amount to the retailer based on the determined percentage
     pay_toretailor=((vmi.read_price_map( productType)*percent_of_retailor)/100);
     //پرداخت به خرده فروش
     //require(balance_map[manufacture]>=penalty1+penalty2+pay_toretailor);
     require(vmi.read_balancemap(vmi.manufacture())>=penalty1+penalty2+_pay_toretailor);
       //balance_map[asigned_retail]=balance_map[asigned_retail]+ pay_toretailor-penalty1;
        vmi.updateadd_balance_map(asigned_retail,_pay_toretailor);
        vmi.updatesub_balance_map(asigned_retail,penalty1);

       //balance_map[custumer_adress]=balance_map[custumer_adress]+ penalty1+penalty2;
        vmi.updateadd_balance_map(custumer_adress,penalty1+penalty2);

       //balance_map[manufacture]=balance_map[manufacture]- pay_toretailor- penalty1-penalty2;
        vmi.updatesub_balance_map(vmi.manufacture(),_pay_toretailor+ penalty1+penalty2);

  }

 }
}

//[1140112100,1140112101,1140112102,3140112300,3140112301,3140112302,3140112303,3140112304,1140112103,1140112104,1140112105,3140112316,3140112317,3140112317,3140112317,3140112317,3140112317,3140112317,1140112106,1140112107,1140112108,1140112109,1140112111,1140112110,1140112112,1140112113,1140113123,2140112217,2140112209,2140112210]
function h_collection_used(uint re_id) public onlycollector {
        address re_adrs=vmi.retailoradress(re_id);
        uint [] memory barcode_used=vmi.read_colected_product_retailor(re_adrs);
        collected_product_map[msg.sender]=barcode_used;
        collected_product_map_pay_status[msg.sender]=barcode_used;
        collected_product_map_pa_government[msg.sender]=barcode_used;
        vmi.u_delete_colected_retailor(re_id);
        delete barcode_used;
}

//Producer payment to collector
function b_pay_collector() onlymanufacture
public payable{
  address collector_adress=vmi.colectoradress();
   uint cost_to_colector=(collected_product_map_pay_status[collector_adress].length)
   *(cost_of_one_colected);
  
   require(  vmi.read_balancemap(vmi.manufacture())>=cost_to_colector);
     //balance_map[manufacture]=balance_map[manufacture]-cost_to_colector;
     vmi.updatesub_balance_map(vmi.manufacture(),cost_to_colector);
     //balance_map[collector_adress]=balance_map[collector_adress]+cost_to_colector;
     vmi.updateadd_balance_map(collector_adress,cost_to_colector);
     //balance_map[collector_adress]=balance_map[collector_adress]);
     delete collected_product_map_pay_status[collector_adress];
}


// Government incentive payment to the produce
function hhh_encouragement(uint encourage_one_product, bool _barcode_status) 
onlygovernment payable public
{
//Incentive payment is collected for products
   require (_barcode_status=true);
   uint s=0;
     address _clc_adr=vmi.colectoradress();
     uint leng=collected_product_map_pa_government[_clc_adr].length;
     uint encour_cost=(leng)*(encourage_one_product);
      s=encour_cost;
      delete collected_product_map_pa_government[_clc_adr];
    //require(balance_map[govenrnment]>=s);
    require(vmi.read_balancemap(vmi.govenrnment())>=s);
     //balance_map[vmi.manufacture()]=balance_map[manufacture]+s;
     //balance_map[]=balance_map[govenrnment]-s;
     vmi.updateadd_balance_map(vmi.manufacture(),s);
     vmi.updatesub_balance_map(vmi.govenrnment(),s);

}


function i_build_difrence_barcodemap(uint [] memory uncolected_barcode)
 onlygovernment public{
      difrence_barcode_map[i_of_difrence_barcode_map]=uncolected_barcode;
      i_of_difrence_barcode_map=i_of_difrence_barcode_map+1;
}

function ii_penalty_uncollected(uint penalty_uncolected_product) 
onlygovernment public payable {
  uint [] memory diference_product_uncolected =difrence_barcode_map[Last_number_paid];
  uint penalty_manuf=diference_product_uncolected.length*penalty_uncolected_product;
   Last_number_paid= Last_number_paid+1;
   require(vmi.balance_map(vmi.manufacture())>=penalty_manuf);
    vmi.updateadd_balance_map(vmi.govenrnment(),penalty_manuf);
    vmi.updateadd_balance_map(vmi.manufacture(),penalty_manuf);

  }

modifier  onlymanufacture(){ //only manufacture can do it
        require(manufacture== msg.sender); 
        _;
    }
modifier  onlycollector() { //only collector can do it
   require(msg.sender==colectoradress);
_;
}

modifier  onlygovernment(){ //only government can do it
        require(govenrnment== msg.sender); 
        _;
    }   

}


//Contract related to time calculations

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }





        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}


