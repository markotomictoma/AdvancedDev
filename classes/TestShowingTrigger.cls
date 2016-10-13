@isTest public class TestShowingTrigger { 
	static testmethod void TestShowingName(){
		Feature__c f = TestDataGenerator.CreateFeaturs(1)[0];
		insert f;
		List<Showing__c> showings = TestDataGenerator.CreateShowings(f.Id, 400);
		insert showings;
		Showing__c showing = [select name, date__c, Start_Time__c from Showing__c where id =: showings[0].Id][0];
		System.assertEquals(String.valueOf(showing.Date__c) + ' ' + showing.Start_Time__c + ' ' + f.Name, showing.Name);
	}

	static testmethod void TestTreilerImpressions(){
		List<Feature__c> features = TestDataGenerator.CreateFeaturs(2);
		insert features;
		List<Showing__c> showings = TestDataGenerator.CreateShowings(features[1].Id, 2);
		insert showings;

		List<Trailer__c> trailers = new List<Trailer__c>();
		trailers.add(TestDataGenerator.CreateTrailer(features[0].Id, showings[0].Id));
		trailers.add(TestDataGenerator.CreateTrailer(features[0].Id, showings[1].Id));
		insert trailers;

		showings[0].tickets_sold__c = 100;
		showings[0].start_time__c = '7:00 PM';
		update showings[0];
		showings[1].tickets_sold__c = 500;
		showings[1].start_time__c = '9:30 PM';
		update showings[1];
		Feature__c savedFeature = [select Trailer_Impressions__c from Feature__c where id =: features[0].id];
		System.assertEquals(600, savedFeature.Trailer_Impressions__c);

		delete showings;
		savedFeature = [select Trailer_Impressions__c from Feature__c where id =: features[0].id];
		System.assertEquals(0, savedFeature.Trailer_Impressions__c);

		undelete showings;
		savedFeature = [select Trailer_Impressions__c from Feature__c where id =: features[0].id];
		System.assertEquals(600, savedFeature.Trailer_Impressions__c);
	}
}