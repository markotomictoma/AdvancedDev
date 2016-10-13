public class ShowingHandler extends BaseTriggerHandler { 
	
	protected override void BeforeInsert(){
		BuildName();
	}

	protected override void BeforeUpdate(){
		BuildName();
	}

	protected override void AfterUpdate(){
		Set<Id> showingIdsWithChangedTicketsSold = new Set<Id>();// prepare set of showing ids whre tickets sold is changed
		for(Sobject newShowing : Trigger.new){
			if(((Showing__c)newShowing).Tickets_Sold__c != ((Showing__c)Trigger.oldMap.get(newShowing.Id)).Tickets_Sold__c){
				showingIdsWithChangedTicketsSold.add(newShowing.Id);
			}
		}
		CalculateTrailerExpressions(showingIdsWithChangedTicketsSold);
	}

	protected override void BeforeDelete(){
		DeleteImpressions();
	}

	protected override void AfterUndelete(){
		CalculateTrailerExpressions(Trigger.newMap.keyset());
	}
	
	private void BuildName(){
		Set<Id> featureIds = new Set<Id>();
		for(SObject s : trigger.new){
			featureIds.add(((Showing__c)s).feature__c);
		}

		for(Feature__c f : [select Name from Feature__c where id in: featureIds]){
			for(SObject s : trigger.new){
				Showing__c lShowing = (Showing__c)s;
				if(lShowing.feature__c == f.Id){
					lShowing.Name = String.format('{0} {1} {2}', new List<String>{String.valueOf(lShowing.date__c), String.valueOf(lShowing.start_time__c), f.Name});
				}
			}
		}
	}

	//ONLY IMPLEMENTED ON SHOWING UPDATE SINCE REQUIREMENT STATED "WHEN THE TICKETS SOLD FIELD IS UPDATED...". HOWEVER, IT NOWHERE STATED THAT TRAILER IMPRESSIONS SHOULD BE RECALCULATED IF TICKETS SOLD FIELD IS POPULATED ON INSERT OR
	//LOADED VIA DATALOAD. THAT IS WHY IF YOU CREATE SHOWING WITH TRAILERS AND IMMEDIATIELY SET TICKETS SOLD, RELATED TRAILER'S FEATURES WILL NOT BE UPDATED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	private void CalculateTrailerExpressions(Set<Id> showingIds){
		if(showingIds.size() == 0){
			return;
		}

		Set<Id> affectedFeatureIds = new Set<Id>();//affected feature Ids are all Feature Ids whose trailers are showed on the context showings
		for(Trailer__c trailer : [select Feature__c from Trailer__c where Showing__c in: showingIds]){
			affectedFeatureIds.add(trailer.Feature__c);
		}

		Set<Id> relatedShowingIds = new Set<Id>();// Related Showing Ids are all Showing Ids where affectedFeatureIds are shown as a trailer, not only context showing Ids
		for(Trailer__c trailer : [select Showing__c from Trailer__c where Feature__c in: affectedFeatureIds]){
			relatedShowingIds.add(trailer.Showing__c);
		}

		Map<Id, Set<Id>> featureId2ShowingIds = new Map<Id, Set<Id>>();//maps feature and Showings where this feature is shown as a trailer
		for(Trailer__c trailer : [select Showing__c, Feature__c from Trailer__c where Showing__c in: relatedShowingIds]){
			if(featureId2ShowingIds.containsKey(trailer.feature__c)){
				featureId2ShowingIds.get(trailer.feature__c).add(trailer.showing__c);
			}else{
				featureId2ShowingIds.put(trailer.feature__c, new Set<Id>{trailer.showing__c});
			}
		}

		Map<Id, Showing__c> showingId2Showing = new Map<id, Showing__c>([select Tickets_sold__c from Showing__c where id in: relatedShowingIds]);// map of shoiwngid and showing to be used to get showing for given id
		List<Feature__c> features = new List<Feature__c>();//features to be updated with new trailer expressions
		system.debug(featureId2ShowingIds);
		for(Id featureId : featureId2ShowingIds.keySet()){
			Decimal newTrailerExpressions = 0;
			for(Id showingId : featureId2ShowingIds.get(featureId)){
				Showing__c lShowing = showingId2Showing.get(showingId);
				if(lShowing.Tickets_Sold__c != null){
					newTrailerExpressions += lShowing.Tickets_Sold__c;
				}
			}
			features.add(new Feature__c(id = featureId, Trailer_Impressions__c = newTrailerExpressions));
		}
		update features;
	}

	private void DeleteImpressions(){
		//get all related trailers and their features
		List<Showing__c> showingsWithTrailers = [select tickets_sold__c, (select feature__c, feature__r.Trailer_Impressions__c from trailers__r) 
												 from Showing__c where id in: trigger.oldMap.keySet()];
		for(SObject so : showingsWithTrailers){//
			Showing__c lShowing = (Showing__c)so;
			if(lShowing.tickets_sold__c != null){
				for(Trailer__c t : lShowing.trailers__r){//update every related feature trailer expressions. In this case tickets sold of deleted showings will be substracted from current implressions
					t.feature__r.Trailer_Impressions__c -= lShowing.tickets_sold__c;
				}
			}
		}
		Map<Id, Feature__c> featureId2Feature = new Map<Id, Feature__c>();// combine related features into one Map, preparation for update
		for(SObject so : showingsWithTrailers){
			Showing__c lShowing = (Showing__c)so;
			for(Trailer__c t : lShowing.trailers__r){
				if(!featureId2Feature.containsKey(t.feature__c)){
					featureId2Feature.put(t.feature__c, t.feature__r);
				}
			}
		}
		update featureId2Feature.values();
	}
}