import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.BufferedReader;
import java.io.BufferedWriter;

public final class Preprocess{
    public static boolean Processor(String file){
        
        try{
            Process p = Runtime.getRuntime().exec("./tokenizer/scanner " + file);
            BufferedReader output = new BufferedReader(new InputStreamReader(p.getInputStream()));
            BufferedWriter input = new BufferedWriter(new OutputStreamWriter(p.getOutputStream()));
            BufferedReader error = new BufferedReader(new InputStreamReader(p.getErrorStream()));
            while (p.isAlive() || output.ready() || error.ready()){
                if(output.ready()){
                    String item = output.readLine();
                    try{
                        String name = Class.forName("java.lang." + item).getSimpleName();
                        System.out.println(name);
                        input.write((name + "\n" + "true\n" + item + "\n"));
                    }
                    catch(Exception e){
                        input.write(("none\n" + "false\n" + item + "\n"));
                    }
                    input.flush();
                }
                if (error.ready()){
                    System.out.println(error.readLine());
                }
            }
            p.waitFor();
            return p.exitValue() == 0;
        }
        catch(Exception ex){
            ex.printStackTrace();
        }
        return false;
    }

    public static void main(String args[]){
        if (args.length != 1){
            System.out.println("Error: preprocessor requires 1 input file");
            return;
        }
        
        final String[] extension = args[0].split("\\.");
        if(extension.length != 2 && extension[1].equals("java")){
            System.out.println("Error: invalid file input, give a .java file");
            return;
        }

        if(!Processor(args[0])){
            System.out.println("Error: preprocessor failed");
            return;
        }

        try{
            Process p = Runtime.getRuntime().exec("javac -d . scanner/" + args[0]);
            p.getErrorStream().transferTo(System.out);
            p.waitFor();
            if(p.exitValue() != 0){
                return;
            }
        }
        catch(Exception ex){
            ex.printStackTrace();
        }

        System.out.println("Program compiled successfully");
    }
}