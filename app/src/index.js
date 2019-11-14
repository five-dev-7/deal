import Web3 from "web3";
import dealArtifact from "../../build/contracts/Deal.json";

const App = {
  web3: null,
  account: null,
  des : Math.pow(10 , 18 ) ,
  deal: null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = dealArtifact.networks[networkId];
      this.deal = new web3.eth.Contract(
        dealArtifact.abi,
        deployedNetwork.address,
      );
      this.initEvent() ;
      this.refreshInfo();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },
  newOrder: async function() {
    const { createOrder } = this.deal.methods;
    
    const title = $("#title").val() ;
    const content = $("#content").val() ;
    const amount = $("#amount").val() ;
    const isBuyer = $("#isBuyer").val() ;
    const exTime = $("#exTime").val() ;

    createOrder( title , content , isBuyer , web3.toWei(amount) ,exTime )
        .send({from:this.account , value : web3.toWei(amount)}).then( res => {
          console.log( res ) ;
        })
  },
  initEvent : function() {
    this.deal.events.createOrderEvent({},
       function(){})
       .on('data', function(result){
         if( result ){
           const _creator = result["returnValues"]["_creator"];
           const _orderNo = result["returnValues"]["_orderNo"];
           $("#status").text(" Creator :  " + _creator + " , OrderNo : " + _orderNo );
         }
        })
    console.log("Init event success.")
  },
  refreshInfo : function() {
    this.account = App.web3.currentProvider.selectedAddress ;
    $(".address").text( this.account ) ;
    App.web3.eth.getBalance( App.web3.currentProvider.selectedAddress ).then(res => {
      $(".balance").text( res/App.des ) ;
    })
  }
}

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://192.168.11.113:7545"),
    );
  }

  App.start() ;
})
