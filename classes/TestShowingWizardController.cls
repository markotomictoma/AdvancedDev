@isTest public class TestShowingWizardController { 
	static testmethod void TestController(){
		List<Feature__c> features = new List<Feature__c>();
		for(integer i = 0; i < 10; i++){
			features.add(TestDataGenerator.CreateFeature('test ' + i, 'Action', date.today().addDays(-i)));
			features.add(TestDataGenerator.CreateFeature('test ' + i, 'Comedy', date.today().addDays(-i)));
			features.add(TestDataGenerator.CreateFeature('test ' + i, 'Drama',  date.today().addDays(-i)));
		}
		insert features;

		PageReference pageRef = Page.ShowingWizard;
		Test.setCurrentPage(pageRef);
		Showing__c showing = new Showing__c();
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(showing);
		ShowingWizardController ctrl = new ShowingWizardController(stdCtrl);
		ctrl.FilterFeatures();
		system.assertEquals(6, ctrl.totalPages);

		ctrl.ShowNext();
		system.assertEquals(2, ctrl.currentPage);
		ctrl.ShowPrevious();
		ctrl.ShowLast();
		system.assert(ctrl.lastRendered);
		ctrl.ShowFirst();
		system.assert(ctrl.firstRendered);

		system.assert(ctrl.getGenres().size() > 0);

		system.assertEquals(false, ctrl.isAtLeastOneFeatureSelected);
		ctrl.featureId2Selected.put(features[5].Id, true);
		system.assertEquals(true, ctrl.isAtLeastOneFeatureSelected);

		List<ShowingWizardController.GenreWedgeData> genreData = ctrl.GetPieData();
		system.assertEquals(1, genreData.size());
		system.assertEquals(features[5].genre__c, genreData[0].genre);
		system.assertEquals(1, genreData[0].cnt);

		ctrl.selectedGenre = 'Action';
		ctrl.FilterFeatures();
		system.assertEquals(2, ctrl.totalPages);
		system.assertEquals(10, ctrl.setCon.getResultSize());

		showing.Start_Time__c = '4:30 PM';
		showing.Feature__c = features[4].Id;
		showing.Screen_Number__c = '5';
		showing.Tickets_Sold__c = 100;
		showing.Date__c = Date.today().addDays(-50);
		ctrl.Save();//negative use case, should not save successfuly 
		System.assertEquals(0, [select Date__c, start_time__c, feature__c, screen_number__c, tickets_sold__c from Showing__c where id =: showing.id].size());
		showing.Date__c = Date.today();
		ctrl.Save();//Positive use case, save should succeed

		Showing__c savedShowing = [select Date__c, start_time__c, feature__c, screen_number__c, tickets_sold__c from Showing__c where id =: showing.id];
		system.assertEquals(showing.Start_Time__c, savedShowing.Start_Time__c);
		system.assertEquals(showing.Feature__c, savedShowing.Feature__c);
		system.assertEquals(showing.Screen_Number__c, savedShowing.Screen_Number__c);
		system.assertEquals(showing.Tickets_Sold__c, savedShowing.Tickets_Sold__c);

		stdCtrl = new ApexPages.StandardController(savedShowing);
		ctrl = new ShowingWizardController(stdCtrl);
		integer cntSelectedFeatures = 0;
		for(Id featureId : ctrl.featureId2Selected.keySet()){
			if(ctrl.featureId2Selected.get(featureId)){
				cntSelectedFeatures++;
			}
		}
		system.assertEquals(1, cntSelectedFeatures);

		ctrl.selectedGenre = 'Action';
		ctrl.FilterFeatures();
		system.assertEquals(1, ctrl.totalPages);
		system.assertEquals(1, ctrl.setCon.getResultSize());
	}
}