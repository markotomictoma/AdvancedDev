public class TestDataGenerator { 
	public static List<Feature__c> CreateFeaturs(integer numOfFeatures){
		List<Feature__c> features = new List<Feature__c>();
		for(integer i = 1; i <= numOfFeatures; i++){
			features.add(CreateFeature('Test Feature Name ' + i, null, null));
		}
		return features;
	}

	public static Feature__c CreateFeature(String fName, String genre, Date releaseDate){
		return new Feature__c(name = fName, genre__c = genre, release_date__c = releaseDate);
	}

	public static List<Showing__c> CreateShowings(ID featureId, integer numOfShowings){
		List<Showing__c> showings = new List<Showing__c>();
		for(integer i = 1; i <= numOfShowings; i++){
			showings.add(new Showing__c(Feature__c = featureId, Date__c = Date.today(), Start_Time__c = '9:30'));
		}
		return showings;
	}

	public static Trailer__c CreateTrailer(ID featureId, ID showingID){
		return new Trailer__c(Feature__c = featureId, Showing__c = showingId);
	}
}