trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

    List<ContentDocumentLink> updates = new List<ContentDocumentLink>();

    for (ContentDocumentLink cdl : Trigger.new) {

        if (cdl.LinkedEntityId != null &&
            cdl.LinkedEntityId.getSObjectType() == Staff__c.SObjectType) {

            updates.add(new ContentDocumentLink(
                Id = cdl.Id,
                Visibility = 'AllUsers'
            ));
        }
    }

    if (!updates.isEmpty()) {
        update updates;
    }
}