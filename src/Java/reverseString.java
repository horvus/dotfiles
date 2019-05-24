// Basic Java program to test the syntax.

import java.util.Scanner;

public class reverseString {

    private static void reverse(String text) {
        for(int i = text.length() - 1; i >=0; i--) {
            System.out.print(text.charAt(i));
        }
        System.out.println();
    }

    public static void main(String args[]) {
        System.out.println("Enter a string: ");
        String text;

        Scanner scanIn = new Scanner(System.in);
        text = scanIn.nextLine();
        scanIn.close();

        System.out.println("You entered: " + text);

        reverse(text);
    }
}
