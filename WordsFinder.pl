#!/usr/bin/perl
use strict;
use warnings;

use Path::Class;
use autodie;

# Zmienne globalne
my $fileHandle;
my %wordsPlaces;
my %wordsOrder;
my $regexToFind;
my @wordsInRegex;

# Wczytanie pliku txt, stworzenie plikow dbm oraz indeksowanie pliku txt.
loadTxtFile();
openDbmFiles();
clearDbmFiles();
indexTxtFile();

# Petla umozliwiajaca wyszukiwanie pojedynczych slow oraz regexow.
while(1) {
	print "\nPodaj szukaną frazę:\n";
	chomp($regexToFind = <STDIN>);

	@wordsInRegex = split ' ', $regexToFind;

	print "Znaleziono \"$regexToFind\" w następujących miejscach:";

	if(0+@wordsInRegex > 1) {
		findRegex();
	} else {
		findWord();
	}
	
	print "\nKontynuować wyszukiwanie? (N - nie)\n";
	chomp(my $answer = <STDIN>);
	if($answer eq "N") {
		exit 0;
	}
}

closeDbmFiles();

# Wczytanie pliku tekstowego
sub loadTxtFile{
	print "Podaj sciezke do pliku tekstowego:\n";
	chomp(my $filePath = <STDIN>);
	my $file = file($filePath);
	$fileHandle = $file->openr();
}

# Stworzenie/otwarcie plikow dbm
sub openDbmFiles{
	print "-> Tworzenie plikow dbm\n";

	dbmopen(%wordsPlaces, "wordsPlaces", 0644) || die "Nie można otworzyć pliku DBM: $!";
	dbmopen(%wordsOrder, "wordsOrder", 0644) || die "Nie można otworzyć pliku DBM: $!";
}

# Wyczyszczenie plikow dbm
sub clearDbmFiles{
	%wordsPlaces = ();
	%wordsOrder = ();
}

# Zamkniecie plikow dbm
sub closeDbmFiles{
	clearDbmFiles();
	dbmclose(%wordsPlaces);
	dbmclose(%wordsOrder);
}

# Indeksowanie pliku tekstowego
sub indexTxtFile{
   print "-> Indeksowanie pliku tekstowego\n";

   my $wordIndexInFile = 1;
   for (my $lineNumber = 1; my $line = $fileHandle->getline(); ++$lineNumber) {
	print "->	Indeksowanie: linia $lineNumber\n";

	chomp $line;
	my @words = split ' ', $line; 

	my $actualIndexInLine = 0;
	foreach my $word (@words) {
		$wordsOrder{$wordIndexInFile} = $word;

		$actualIndexInLine = $actualIndexInLine + 1;
		if (defined $wordsPlaces{$word}) {
			$wordsPlaces{$word} = "$wordsPlaces{$word};$lineNumber, $actualIndexInLine";
		} else {
    			$wordsPlaces{$word} = "$lineNumber, $actualIndexInLine";
		}
		$actualIndexInLine = $actualIndexInLine + (length $word);
		$wordIndexInFile = $wordIndexInFile + 1;
	}
}
}

# Wyszukanie wyrazenia regularnego
sub findRegex{
	my @pairs;
	if (defined $wordsPlaces{$wordsInRegex[0]}) {
		@pairs = split /;/, $wordsPlaces{$wordsInRegex[0]};
	}

	my $pairIndex = 0;
	my $key;

	foreach $key (sort {$a <=> $b} keys %wordsOrder) {
		if($wordsOrder{$key} eq $wordsInRegex[0]) {
			my $i = 0;
			foreach my $word (@wordsInRegex) {
				if(!($wordsOrder{$key+$i} eq $word)) {
					return;
				}
				$i = $i + 1;
			}
			print "\n(wiersz, kolumna) = $pairs[$pairIndex]";
			$pairIndex = $pairIndex + 1;
		}
	}
}

# Wyszukanie pojedynczego slowa
sub findWord{
	my @pairs;
	if (defined $wordsPlaces{$regexToFind}) {
		@pairs = split /;/, $wordsPlaces{$regexToFind};
	}

	my $pairIndex = 0;
	my $key;

	foreach $key (sort {$a <=> $b} keys %wordsOrder) {
		
		if($wordsOrder{$key} eq $regexToFind) {
			print "\n(wiersz, kolumna) = $pairs[$pairIndex]";
			print "\tKontekst: \"";
			if(defined $wordsOrder{$key-3}) {
				print "$wordsOrder{$key-3} ";
			}
			if(defined $wordsOrder{$key-2}) {
				print "$wordsOrder{$key-2} ";
			}
			if(defined $wordsOrder{$key-1}) {
				print "$wordsOrder{$key-1} ";
			}
			print "$wordsOrder{$key}";
			if(defined $wordsOrder{$key+1}) {
				print " $wordsOrder{$key+1}";
			}
			if(defined $wordsOrder{$key+2}) {
				print " $wordsOrder{$key+2}";
			}
			if(defined $wordsOrder{$key+3}) {
				print " $wordsOrder{$key+3}";
			}
			print "\"";
			$pairIndex = $pairIndex + 1;
		}
	}
}
