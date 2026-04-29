public class ChatterHelper {

    @InvocableMethod(label='Clean HTML from Chatter Body')
    public static List<String> cleanBody(List<String> bodies) {

        List<String> cleanedList = new List<String>();

        for(String body : bodies){
            if(body != null){
                String clean = body.replaceAll('<[^>]*>', '');
                cleanedList.add(clean);
            } else {
                cleanedList.add('');
            }
        }
        return cleanedList;
    }
}