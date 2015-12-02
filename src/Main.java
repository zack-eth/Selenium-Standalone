package com.jsc;

import java.util.Random;
import java.util.List;
import java.util.ArrayList;
import java.util.Locale;
import java.util.Date;
import java.util.TimeZone;
import java.util.logging.Logger;
import java.util.logging.Level;
import java.text.NumberFormat;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.io.FileNotFoundException;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.htmlunit.HtmlUnitDriver;
import org.openqa.selenium.NoSuchElementException;

import com.gargoylesoftware.htmlunit.WebClient;
import com.gargoylesoftware.htmlunit.SilentCssErrorHandler;

import cucumber.api.java.en.Given;
import cucumber.api.java.en.And;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;
import cucumber.api.PendingException;

import static org.junit.Assert.assertEquals;

public class Main {

  private static final String QUOTE_URL_TEMPLATE = "https://www.google.com/finance?q=%s";
  private static final String SYMBOLS_URL = "https://finance.yahoo.com/q/cp?s=%5ENDX";

  private WebDriver driver;

  String symbol;
  int quantity;
  double price;
  double cost;

  public Main() throws FileNotFoundException {
    WebClient webClient = new WebClient();
    webClient.setCssErrorHandler(new SilentCssErrorHandler());
    Logger.getLogger("com.gargoylesoftware").setLevel(Level.OFF);
    Logger.getLogger("org.apache").setLevel(Level.OFF);
    driver = new HtmlUnitDriver();
  }

  @Given("^a random symbol$")
  public void randomSymbol() throws Throwable {
    String[] symbols = getSymbols();
    Random random = new Random();
    int randomIndex = random.nextInt(symbols.length);
    symbol = symbols[randomIndex];
    System.out.println("\n" + "Symbol: " + symbol);
  }

  @And("^a random quantity$")
  public void randomQuantity() throws Throwable {
    Random random = new Random();
    quantity = random.nextInt((1000 - 100) + 1) + 100;
    System.out.println("Quantity: " + quantity);
  }

  @When("^I place an order$")
  public void placeOrder() throws Throwable {
    price = getPrice();
    cost = price * quantity;
    System.out.println("Cost: " + toMoney(cost) + "\n");
  }

  @Then("^the cost should equal the price times the quantity$")
  public void assertCost() throws Throwable {
    //assertEquals(cost, price * quantity, 0.1);
    throw new PendingException();
  }

  private String[] getSymbols() throws Exception {
    List<String> symbols = new ArrayList<String>();
    driver.get(SYMBOLS_URL);
    List<WebElement> elements = driver.findElements(By.cssSelector(".yfnc_tabledata1 a"));
    if (elements.isEmpty()) {
      System.exit(123);
    }
    for (WebElement element : elements) {
      symbols.add(element.getText());
    }
    return symbols.toArray(new String[symbols.size()]);
  }

  private double getPrice() {
    String url = String.format(QUOTE_URL_TEMPLATE, symbol);
    driver.get(url);
    WebElement span = null;
    try {
      span = driver.findElement(By.cssSelector("#price-panel .pr"));
    }
    catch (NoSuchElementException e) {
      System.exit(234);
    }
    String strValue = span.getText();
    double currentPrice = Double.parseDouble(strValue);
    System.out.println("Price: " + toMoney(currentPrice));
    return currentPrice;
  }

  private static String toMoney(double decimal) {
    return NumberFormat.getCurrencyInstance(new Locale("en", "US")).format(decimal);
  }

  public static void main(String[] args) throws Throwable {
    String osName = System.getProperty("os.name");
    String osVersion = System.getProperty("os.version");
    String osArch = System.getProperty("os.arch");
    System.out.println(osName + " " + osVersion + " " + osArch);
    Date date = new Date();
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss aa z");
    df.setTimeZone(TimeZone.getDefault());
    System.out.println(df.format(date));
    Main main = new Main();
    main.randomSymbol();
    main.randomQuantity();
    main.placeOrder();
  }

}
