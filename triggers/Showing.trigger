trigger Showing on Showing__c (before Insert, before update, after update, before delete, after delete, after undelete) {
	(new ShowingHandler()).Handle();
}