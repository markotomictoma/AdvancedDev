public class ShowingWizardController { 
	
	//Paging properties, nothing interesting here
	private final Integer pageSize = 5;
	public final Showing__c showing;
	public Integer currentPage {
		public get{
			return setCon.getPageNumber();
		}
		private set;
	}
	public Integer totalPages{
		public get{
			if(setCon.getResultSize() == 0){
				return 0;
			}else{
				if(math.mod(setCon.getResultSize(), setCon.getPageSize()) != 0){//calculates number of pages based on the MOD of total records number and specified page size. 
					return setCon.getResultSize()/setCon.getPageSize() + 1;
				}
			}
			return setCon.getResultSize()/setCon.getPageSize();
		}
	}
	public Boolean firstRendered{
		get{
			return currentPage == 1;
		}
	}
	public Boolean lastRendered{
		get{
			return currentPage == totalPages;
		}
	}
	public String selectedGenre{get; set;}//gets value from the genre picklist change
	public Map<Id, Boolean> featureId2Selected {//map that maintains selected features. On Page Load is map initialized and preselected if there are saved trailers. Binded to pageblocktable
		get{
			if(featureId2Selected == null){
				featureId2Selected = new Map<Id, Boolean>();
			}
			return featureId2Selected;
		} 
		private set;
	}
	public Boolean isAtLeastOneFeatureSelected{
		get{
			for(Boolean featureSelected : featureId2Selected.values()){
				if(featureSelected){
					return true;
				}
			}
			return false;
		}
	}

	public ShowingWizardController(ApexPages.StandardController ctrl){
		this.showing = (Showing__c)ctrl.getRecord();
		system.debug(showing);
		InitShowingData();
		InitTrailersData();
	}

	public ApexPages.StandardSetController setCon {//standard Salesforce Set controller. Here is the logic what should be selected in case of no selected genres and in case of new/edit
        get {
            if(setCon == null) {
				Set<Id> relatedFeatureIds = new Set<Id>();
				if(showing.Id != null){
					for(Trailer__c trailer : [select Feature__c from Trailer__c where Showing__c =: showing.Id]){
						relatedFeatureIds.add(trailer.Feature__c);
					}
				}
				if(selectedGenre == null || selectedGenre == '-1'){//on new record page load or when user selects any type
					if(showing.Id != null){
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Release_Date__c, Genre__c FROM Feature__c where Id !=: showing.Feature__c and (Release_Date__c >=: showing.Date__c or (Release_Date__c <: showing.Date__c and id in: relatedFeatureIds)) order by Release_Date__c asc, name]));
					}else{
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Release_Date__c, Genre__c FROM Feature__c order by Release_Date__c asc, name]));
					}
				}else{
					if(showing.Id != null){
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Release_Date__c, Genre__c FROM Feature__c where Genre__c =: selectedGenre and Id !=: showing.Feature__c and (Release_Date__c >=: showing.Date__c or (Release_Date__c <: showing.Date__c and id in: relatedFeatureIds)) order by Release_Date__c asc, name]));
					}else{
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Release_Date__c, Genre__c FROM Feature__c where Genre__c =: selectedGenre order by Release_Date__c asc, name]));
						system.debug(setCon.getRecords());
					}
				}
            }
            return setCon;
        }
        set;
    }
 
    public List<Feature__c> GetFeatures() {//takes the records from set controller, sets the page size and initializes the map of selected features
		setCon.setPageSize(pageSize);
		List<Feature__c> results = (List<Feature__c>) setCon.getRecords();
		for(Feature__c feature : results){
			if(!featureId2Selected.containsKey(feature.Id)){
				featureId2Selected.put(feature.Id, false);
			}
		}
        return results;
    }

	//Paging methods. They do nothing, just calls the build in standard set controller's methods
	public PageReference ShowNext(){
		setCon.Next();
		return null;
	}

	public PageReference ShowPrevious(){
		setCon.Previous();
		return null;
	}

	public PageReference ShowFirst(){
		setCon.First();
		return null;
	}

	public PageReference ShowLast(){
		setCon.Last();
		return null;
	}

	public List<SelectOption> getGenres()//retrieves all picklist values from genre field
	{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('-1', '--Any Type--'));
        
	    Schema.DescribeFieldResult fieldResult = Feature__c.Genre__c.getDescribe();
	    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
	    for( Schema.PicklistEntry f : ple)
	    {
		    options.add(new SelectOption(f.getValue(), f.getLabel()));
	    }       
	    return options;
	}

	public PageReference FilterFeatures(){//called upon genre picklist change. Resets the standard set controller and creates new for new selected genre. 
		setCon = null;
		GetFeatures();
		return null;
	}

	public List<GenreWedgeData> getPieData() {//For selected features creates List of DTOs. Used as a bind variable for Chart component
		Set<Id> selectedFeatureIds = new Set<Id>();
		for(Id featureId : featureId2Selected.keySet()){
			if(featureId2Selected.get(featureId)){
				selectedFeatureIds.add(featureId);
			}
		}
        List<GenreWedgeData> data = new List<GenreWedgeData>();
		if(selectedFeatureIds.size() > 0){//selects number of appereances for every genre for selected features
			for(AggregateResult agg : [select count(id) cnt, Genre__c from Feature__c where id in: selectedFeatureIds  group by Genre__c]){
				data.add(new GenreWedgeData((String)agg.get('Genre__c'), Integer.valueOf(agg.get('cnt'))));
			}
		}
        return data;
    }

	private void InitShowingData(){//per requirement, defaults showing_date__c to today for Creation of new Showing
		if(this.showing.Id == null){
			this.showing.Date__c = Date.today();
		}
	}

	private void InitTrailersData(){//in edit mode initializes map of selected features. Used in pageblocktable checkbox column
		if(showing.Id != null){
			for(Trailer__c trailer : [select Feature__c from Trailer__c where Showing__c =: showing.Id]){
				featureId2Selected.put(trailer.Feature__c, true);
			}
		}
	}

	public PageReference Save(){// saves showing then deletes existing trailers and then creates new ones for every selected Feature
		Savepoint sp = Database.setSavepoint();
		try{
			upsert showing;
			delete [select id from Trailer__c where Showing__c =: showing.Id];
			List<Trailer__c> trailers2Insert = new List<Trailer__c>();
			for(Id featureId : featureId2Selected.keySet()){
				if(featureId2Selected.get(featureId)){
					trailers2Insert.add(new Trailer__c(Feature__c = featureId, Showing__c = showing.Id));
				}
			}
			insert trailers2Insert;
			return new PageReference('/' + showing.Id);
		}catch(Exception e){
			Database.rollback(sp);
			ApexPages.addMessage(new APexPages.Message(ApexPages.Severity.Error, e.GetMessage()));
		}
		return null;
	}

    public class GenreWedgeData {//DTO Class used as data source for Chart
        public String genre { get; set; }
        public Integer cnt { get; set; }
        public GenreWedgeData(String genre, Integer cnt) {
            this.genre = genre;
            this.cnt = cnt;
        }
    }
}