public class TrailerHandler extends BaseTriggerHandler { 
	
	protected override void AfterInsert(){
		SetPrimaryGenre(null);
	}

	protected override void AfterUpdate(){
		SetPrimaryGenre(null);
	}

	protected override void AfterDelete(){
		Set<Id> showingIds = new Set<Id>();
		for(SObject s : trigger.old){
			showingIds.add(((Trailer__c)s).showing__c);
		}
		SetPrimaryGenre(showingIds);
	}

	protected override void AfterUndelete(){
		SetPrimaryGenre(null);
	}
	
	private void SetPrimaryGenre(Set<Id> showingIds ){
		if(showingIds == null){
			showingIds = new Set<Id>();
			for(Sobject s : trigger.new){
				showingIds.add(((Trailer__c)s).showing__c);
			}
		}
		
		List<AggregateResult> aggs = [select showing__c, count(showing__r.name) cnt, feature__r.genre__c primaryGenre 
									from trailer__c 
									where showing__c in: showingIds 
									group by rollup(showing__c, feature__r.genre__c) 
									order by showing__c, count(showing__r.name) desc, feature__r.genre__c asc];

		Map<Id, string> showingId2PrimaryGenre = new Map<Id, string>();
		for(AggregateResult agg : aggs){
			if(agg.get('showing__c') != null && agg.get('primaryGenre') != null && !showingId2PrimaryGenre.containsKey((Id)agg.get('showing__c'))){
				showingId2PrimaryGenre.put((Id)agg.get('showing__c'), String.valueOf(agg.get('primaryGenre')));
			}
		}

		List<Showing__c> showings2Update = new List<Showing__c>();
		for(Id showingId : showingIds){
			if(showingId2PrimaryGenre.containsKey(showingId)){
				showings2Update.add(new Showing__c(Id = showingId, primary_genre__c = showingId2PrimaryGenre.get(showingId)));
			}else{
				showings2Update.add(new Showing__c(Id = showingId, primary_genre__c = ''));//here empty string because of requirement but it will be saved as NULL!
			}
		}
		update showings2Update;
	}
}