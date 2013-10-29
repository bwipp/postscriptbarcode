import java.io.*;
import java.util.regex.*;
import javax.print.*;
import javax.print.attribute.*;

public class UPCAs {      
    
    public static void main(String[] args) throws Exception {
	
        if (args.length!=2) 
            throw new Exception("Requires two arguments");
	
        String template="";
        try {
            BufferedReader in=new BufferedReader(new FileReader("barcode.ps"));
            String line;
            while ((line=in.readLine())!=null)
                template+=line+"\n";
            in.close();
        } catch (IOException e) {        
            throw new Exception("File not found");           
        }                

        Matcher m=Pattern.compile(
            "(?s).*% --BEGIN TEMPLATE--(.*)"+
            "% --END TEMPLATE--.*").matcher(template);
        if (!m.matches()) 
            throw new Exception("Unable to parse out template");
        
        String contents="%!PS-Adobe-2.0\n"+m.group(1);     
        for (int i=Integer.parseInt(args[0]), j=0; 
	     i<Integer.parseInt(args[1]); i++, j++) {
            int x=100+150*(j/7);
            int y=100+100*(j%7);            
            contents+="gsave\n";
            contents+=x+" "+y+" translate\n";
            contents+="(9781860"+i+") () ean13 barcode\n";
            contents+="grestore\n";                        
        }
        contents+="showpage\n";
        
        try {           
            ByteArrayInputStream in=new ByteArrayInputStream(contents.getBytes());
            DocFlavor flavor=DocFlavor.INPUT_STREAM.AUTOSENSE;
            PrintRequestAttributeSet pras=
                new HashPrintRequestAttributeSet();            
            PrintService service=PrintServiceLookup.
                lookupPrintServices(flavor,pras)[0];
            if (service==null) 
                throw new Exception("Could not locate printer");
            service.createPrintJob().print(new SimpleDoc(in,flavor,new HashDocAttributeSet()),pras);           
        } catch (PrintException e) {            
            throw new Exception("Failed to print");
        }                        

    }    

}

