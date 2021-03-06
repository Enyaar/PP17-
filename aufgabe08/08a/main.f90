program poisson
	use mpi
	use initialize
	use run
	use finalize
	!
	implicit none
	!
	! parameter:
	integer, parameter :: edgeLength = 97	! Kantenlänge der gesamten Matrix
	!Erlaubte outputSize-möglichkeiten (bei edgelength = 97): 3, 5, 9, 24, 47, 93, 185
	integer, parameter :: outputSize = 9	! Kantenlänge der ausgegebenen Matrix
	integer, parameter :: loopSize = 100000	! Anzahl der Iterationen
	! mpi:
	integer :: mpi_rank, mpi_size, tag, status(MPI_STATUS_SIZE), mpi_ierr !MPI
	integer :: mpi_master, mpi_last ! Besondere Prozess IDs
	! data:
	double precision, dimension(:,:), allocatable :: matrix ! or whatever fits
	!double precision, dimension(:,:), allocatable :: temp
	! auxiliary
	integer :: lineCount ! die Anzahl der Zeilen in der einzelnen Matrix
	integer :: offset ! = Index der ersten eigenen Zeile in Gesamtmatrix
	logical :: checkExit =.False. ! Abbruchbedingung
	integer :: i, j !Schleifenvariablen
	
	! performance measurement:
	real :: startTime, endTime
	! für Ausgabe	
	integer :: interlines ! Abstand zwischen Zeilen, die ausgegeben werden sollen
	integer :: currentRow = 1 ! Laufender Zähler für Ausgabe über alle Prozesse
	interlines = (edgeLength-1) / (outputSize - 1)

	! INIT
	call MPI_INIT(mpi_ierr)
	call MPI_COMM_SIZE(MPI_COMM_WORLD,mpi_size,mpi_ierr)
	call MPI_COMM_RANK(MPI_COMM_WORLD,mpi_rank,mpi_ierr)
	mpi_master = 0
	mpi_last = mpi_size - 1
	
	! master:
    if (mpi_rank == mpi_master) then
		! Für Zeitmessung:
        call cpu_time(starttime)
		! Fehlerabfrage für ungültige Outputsizes
        if (mod((edgeLength-1),(outputSize-1)) /= 0) then
            write(*,*) "Die Variable outputSize muss so gewählt werden, dass bei der ", & 
            &          "Rechnung [edgeLength-1 / ( outputSize - 1 )] kein Rest entsteht"
            stop
        endif
    endif
	
	! Initialisiert Variablen zur Orientierung in Gesamtmatrix
	call initLineCount(lineCount, offset, edgeLength, mpi_size, mpi_rank)
	! Eigene Matrix nach Bedarf
	call allocateMatrix(matrix, mpi_rank, mpi_size, lineCount, edgeLength)
	! Startbelegung der Matrix
	call initializeMatrix(matrix, mpi_rank, mpi_size, lineCount, offset)
		
	! PROLOG:
    if (mpi_rank == mpi_master) then
        print *, ""
        print *, "Initiale Matrix"
    endif
    call printMatrix(matrix, interlines, offset, lineCount, mpi_rank, mpi_master, mpi_last, mpi_ierr)

	!calculating:
	do i=1,(loopSize + mpi_last)
		call calculate(matrix, mpi_rank, mpi_master, mpi_last, mpi_ierr, loopSize, i)
	end do
	
	! EPILOG
    if (mpi_rank == mpi_master) then
        ! Headline
        print *, ""
        print *, "Matrix nach", loopSize, "Durchläufen"
    endif
    call printMatrix(matrix, interlines, offset, lineCount, mpi_rank, mpi_master, mpi_last, mpi_ierr)
    
    ! Performance:
    if (mpi_rank == mpi_master) then
        call cpu_time(endtime)
    endif
    
    call mpi_barrier(mpi_comm_world, mpi_ierr)
    if (mpi_rank == mpi_master) then
        print *, ""
        print *, "Zeit für diese Rechnung:", (endtime - starttime), "Sekunden"
    endif

	! FINAL
	deallocate(matrix)
	call MPI_FINALIZE(mpi_ierr)

end program poisson
