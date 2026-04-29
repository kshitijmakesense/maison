public class OrderShareController {
    public Order order { get; private set; }
 
    public OrderShareController(ApexPages.StandardController stdController) {
        this.order = (Order)stdController.getRecord();
    }
 
    public PageReference downloadPDF() {
        PageReference pdfPage = Page.OrderPDFPage;
        pdfPage.getParameters().put('id', order.Id);
        pdfPage.setRedirect(true); // Important: triggers the file download
        return pdfPage;
    }
 
    public PageReference emailOrder() {
        return new PageReference('/_ui/core/email/author/EmailAuthor?p3_lkid=' + order.Id + '&retURL=/' + order.Id);
    }
 
    public PageReference save() {
        try {
            update order;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Order saved successfully.'));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving Order: ' + e.getMessage()));
        }
        return null;
    }
 
    public PageReference cancel() {
        return new PageReference('/' + order.Id);
    }
 
    // Add this method for LWC integration
    @AuraEnabled
    public static void generatePDFAndAttach(Id orderId) {
        try {
            // Generate PDF blob from Visualforce page
            PageReference pdfPage = Page.OrderPDFPage;
            pdfPage.getParameters().put('id', orderId);
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                // For test context, create a mock blob
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
 
            // Get order details for attachment name
            Order o = [SELECT Id, OrderNumber, Name FROM Order WHERE Id = :orderId LIMIT 1];
            
            // Create ContentVersion (for Files)
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Order_' + o.OrderNumber + '_' + Date.today().format();
            cv.PathOnClient = cv.Title + '.pdf';
            cv.VersionData = pdfBlob;
            cv.FirstPublishLocationId = orderId; // This links it to the Order record
            cv.ContentLocation = 'S'; // Stored in Salesforce
            insert cv;
            
            // Alternative: Create Attachment (legacy approach, if you prefer)
            /*
            Attachment att = new Attachment();
            att.Name = 'Order_' + o.OrderNumber + '_' + Date.today().format() + '.pdf';
            att.Body = pdfBlob;
            att.ParentId = orderId;
            att.ContentType = 'application/pdf';
            insert att;
            */
        } catch (Exception e) {
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
}