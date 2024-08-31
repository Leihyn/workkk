import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

actor Faruq {

  //define the types for the account
  public type AccountId = Text;
  public type Account = {
    balance: Nat;
    owner: Principal;
    desc: Text;
  };

  stable var accountBackup: [(AccountId, Account)] = [];
  var accountStore = TrieMap.fromEntries<AccountId, Account>(accountBackup.vals(), Text.equal, Text.hash);

  //return the caller's principal
  public shared (msg) func whoami(): async Principal {
    msg.caller
  };
  
  //create a fundable account with an initial balance
  public shared func createAccount(id: Text, initialBalance: Nat, desc: Text): async () {
    let caller =  await whoami();
    //Endure the account is created by the authenticated user
    if (accountStore.get(id) == null) {
      accountStore.put(id, {balance = initialBalance; owner = caller; desc = desc});
    }
  };

  //Transfer funds between accounts
  public shared func transfer(fromId: Text, toId: Text, amount: Nat): async Bool {
    let caller = await whoami();
    let fromAccountOpt = accountStore.get(fromId);
    let toAccountOpt = accountStore.get(toId);

    switch (fromAccountOpt, toAccountOpt) {
      case (?fromAccount, ?toAccount) {
        let isOwner = fromAccount.owner == caller;
        let hasSufficientFunds = fromAccount.balance >= amount;

        if (isOwner){
          if (hasSufficientFunds) {
            //Deduct amount from sender's account
            let updatedFromAccount = {
              fromAccount with balance = fromAccount.balance - amount
            };
            accountStore.put(fromId, updatedFromAccount);

            //add amount to receiver's account
            let updatedToAccount = {
              toAccount with balance = toAccount.balance + amount
            };
            accountStore.put(toId, updatedToAccount);

            return true; //transfer successful
          } else {
            return false; //insufficient funds
          }
        } else {
          return false; //sender is not the owner of the account
        }
        };
      case _ {
        return false; //one or both accounts not found
      };
    }
  };

  // GET account details by ID
  public query func getAccount(id: Text): async ?Account {
    accountStore.get(id);
  };

  //get all accounts
  public query func getAllAccounts(): async [(AccountId, Account)] {
    Iter.toArray(accountStore.entries());
  };

  //get the count of all accounts
  public query func getAccountsCount(): async Nat {
    accountStore.size();
  };

  //backup the data before upgrade
  system func preupgrade() {
    accountBackup := Iter.toArray(accountStore.entries());
  };

  //clear backup data after upgrade
  system func postupgrade() {
    accountBackup := [];
  };

};