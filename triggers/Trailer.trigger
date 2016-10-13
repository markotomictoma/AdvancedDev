trigger Trailer on Trailer__c (after insert, after update, after delete, after undelete)  { 
	(new TrailerHandler()).Handle();
}