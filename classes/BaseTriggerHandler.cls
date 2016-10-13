public abstract class BaseTriggerHandler { 
	protected virtual void BeforeInsert(){}
	protected virtual void AfterInsert(){}
	protected virtual void BeforeUpdate(){}
	protected virtual void AfterUpdate(){}
	protected virtual void BeforeDelete(){}
	protected virtual void AfterDelete(){}
	protected virtual void BeforeUnDelete(){}
	protected virtual void AfterUnDelete(){}

	public virtual void Handle(){
		if(Trigger.isInsert && Trigger.isBefore){
			BeforeInsert();
		}
		if(Trigger.isInsert && Trigger.isAfter){
			AfterInsert();
		}
		if(Trigger.isUpdate && Trigger.isBefore){
			BeforeUpdate();
		}
		if(Trigger.isUpdate && Trigger.isAfter){
			AfterUpdate();
		}
		if(Trigger.isDelete && Trigger.isBefore){
			BeforeDelete();
		}
		if(Trigger.isDelete && Trigger.isAfter){
			AfterDelete();
		}
		if(Trigger.isundelete && Trigger.isBefore){
			BeforeUnDelete();
		}
		if(Trigger.isUndelete && Trigger.isAfter){
			AfterUnDelete();
		}
	}
}