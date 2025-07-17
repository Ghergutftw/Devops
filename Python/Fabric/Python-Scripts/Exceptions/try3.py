try:
    number = int(input("Enter a number: "))
    result = 10 / number
except ValueError:
    print("Invalid input! Please enter a valid number.")

else:
    print(f"The result is: {result}.")

print("This program ends here.")
print("Happy coding.")

