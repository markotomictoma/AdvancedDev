@isTest public class TestTrailerTrigger { 
	static testmethod void TestShowingGenre(){

		List<Feature__c> features = TestDataGenerator.CreateFeaturs(4);
		features[0].Genre__c = 'Action';
		features[1].Genre__c = 'Comedy';
		features[2].Genre__c = 'Drama';
		features[3].Genre__c = 'Drama';
		insert features;

		Showing__c showing = TestDataGenerator.CreateShowings(features[3].Id, 1)[0];
		insert showing;

		List<Trailer__c> trailers = new List<Trailer__c>();
		trailers.add(TestDataGenerator.CreateTrailer(features[0].Id, showing.Id));
		trailers.add(TestDataGenerator.CreateTrailer(features[0].Id, showing.Id));
		trailers.add(TestDataGenerator.CreateTrailer(features[1].Id, showing.Id));
		trailers.add(TestDataGenerator.CreateTrailer(features[2].Id, showing.Id));
		insert trailers;

		showing = [select primary_genre__c from Showing__c where id =: showing.Id];
		System.assertEquals('Action', showing.Primary_Genre__c);

		delete trailers;
		showing = [select primary_genre__c from Showing__c where id =: showing.Id];
		System.assertEquals(null, showing.Primary_Genre__c);// per requirement should be empty string but it is always saves as NULL in DB
		
		//Requirement to support undelete of Trailers. Afer undeleting trailers primary genre has to be same as before deleting
		undelete trailers;
		System.assertEquals(4, [select id from Trailer__c].size());

		showing = [select primary_genre__c from Showing__c where id =: showing.Id];
		System.assertEquals('Action', showing.Primary_Genre__c);
	}
}