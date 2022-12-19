program main

    USE Type_Kinds           , ONLY: FP, IP, DP => Double
    USE LBLRTMIO_Module

    IMPLICIT NONE

    TYPE(LBLRTM_File_type) :: ofile
    INTEGER err_stat
    INTEGER:: i, n,idx
    REAL(DP), ALLOCATABLE :: frequency(:)
    REAL(DP), ALLOCATABLE :: spectrum(:)
    REAL(DP), ALLOCATABLE :: transmission(:)
    REAL(DP), ALLOCATABLE :: TAU_values(:)
    REAL(DP) :: F1(62),F2(62),S1(62),S2(62)
    REAL(DP) :: SUM1,SUM2,PROD1,PROD2,TRANS,DV
    INTEGER :: SIZES(62)

    CHARACTER (LEN=11) :: FNAME
    INTEGER :: NFILES, ID

    CHARACTER(LEN=11) :: ID2ODFILENAME

    print *, 'READ AND Merge WITH ODint files'

    FNAME=ID2ODFILENAME(1)
    CALL GET_ODFILE_DATA_SIZE(FNAME,N,F1(1),F2(1),S1(1),S2(1),.TRUE.)
    PRINT *, 'N=', N
    ALLOCATE(spectrum    (N))
    ALLOCATE(transmission(N))
    ALLOCATE(frequency   (N))
    frequency=0.0
        CALL GET_ODFILE_FREQUENCY(FNAME,frequency(1:N),N)
    NFILES=62
    transmission=0.0
    DO I=1,NFILES
        FNAME=ID2ODFILENAME(I)
        CALL GET_ODFILE_SPECTRUM(FNAME,spectrum(1:N),N)
        transmission(1:N)=transmission(1:N)+spectrum(1:N)
        PRINT *, I, N, F1(1) , '->', F2(1), ' : ', spectrum(1) , '->', spectrum(N)
    ENDDO


    SUM1=transmission(1)
    SUM2=transmission(N)
    PROD1=exp(-1.0*SUM1)
    PROD2=exp(-1.0*SUM2)
    PRINT *, 'PROD FOR ', F1(1), ' = ',SUM1, PROD1, ' COMPARISON FROM TAPE28: 13028.00000000 ->  0.88997799 '
    PRINT *, 'PROD FOR ', F2(1), ' = ',SUM2, PROD2, &
    ' COMPARISON FROM TAPE28:  3051.99984211 ->  0.73147774   AND  3052.00048828  ->  0.73157728 '

    PRINT *, 'Finished Merge'

    ID=64
    OPEN(UNIT=ID,FILE='OD_merged.dat',STATUS='REPLACE')
    DO I=1,N
        WRITE(ID,*) frequency(I), transmission(I)
    ENDDO
    CLOSE(ID)
    PRINT *, 'Merger of OD layers output to OD_merged.dat'

    DO I=1,N
        transmission(I)=exp( -1.0*transmission(I) )
    END DO

    OPEN(UNIT=ID,FILE='TRANSMISSION.dat',STATUS='REPLACE')
    DO I=1,N
        WRITE(ID,*) frequency(I), transmission(I)
    ENDDO
    CLOSE(ID)
    PRINT *, 'Full Transmision calculations output to TRANSMISSION.dat', N

    !    CALL GET_ODFILE_DVSIZE(FNAME,DV)

!    FNAME=ID2ODFILENAME(1)
!    CALL GET_ODFILE_DATA_SIZE(FNAME,N,.TRUE.)
!    FNAME=ID2ODFILENAME(62)
!    CALL GET_ODFILE_DATA_SIZE(FNAME,N,.TRUE.)

end program main

CHARACTER(LEN=11) FUNCTION ID2ODFILENAME(I)

    INTEGER, INTENT(IN) :: I
    CHARACTER (LEN=11) :: FNAME
    CHARACTER(LEN=1)  :: ONECHAR
    CHARACTER(LEN=2)  :: TWOCHAR

    FNAME(1:6)="ODint_"
    IF (I<10) THEN
        WRITE(ONECHAR,'(I1)') I
        FNAME(7:8)="00"
        FNAME(9:9)=ONECHAR
    ELSE
        WRITE(TWOCHAR,'(I2)') I
        FNAME(7:7)="0"
        FNAME(8:9)=TWOCHAR
    ENDIF

    ID2ODFILENAME=FNAME

END FUNCTION ID2ODFILENAME

SUBROUTINE GET_ODFILE_DATA_SIZE(FNAME,N,F1,F2,S1,S2,VERBOSE)

    USE Type_Kinds           , ONLY: FP, IP, DP => Double
    USE LBLRTMIO_Module

    IMPLICIT NONE

    CHARACTER(LEN=11), INTENT(IN)  :: FNAME
    INTEGER,           INTENT(OUT) :: N
    REAL(DP), INTENT(OUT) :: F1,F2,S1,S2
    LOGICAL, INTENT(IN) :: VERBOSE

    TYPE(LBLRTM_File_type) :: ofile
    INTEGER err_stat, M
    REAL(DP), ALLOCATABLE :: frequency(:)

    err_stat = LBLRTM_File_Read(ofile, FNAME)
    IF ( err_stat /= SUCCESS ) THEN
        print *, "handle error..."
        return
    END IF
    IF (VERBOSE) THEN
        print *, "N layers=", ofile%n_Layers
        print *, "N spectra=", ofile%Layer(1)%n_Spectra
        print *, "N points=", ofile%Layer(1)%n_Points
    ENDIF

    N=ofile%Layer(1)%n_Points

    CALL LBLRTM_Layer_Frequency(oFile%Layer(1), frequency)
    m=size(frequency)
    F1=frequency(1)
    F2=frequency(m)

    S1=oFile%Layer(1)%Spectrum(1,1)
    IF (m<n ) THEN
        S2=oFile%Layer(1)%Spectrum(m,1)
        n=m
    ELSE
        S2=oFile%Layer(1)%Spectrum(n,1)
    ENDIF
    CALL LBLRTM_File_Destroy(ofile)
    n=m

END SUBROUTINE GET_ODFILE_DATA_SIZE

SUBROUTINE GET_ODFILE_SPECTRUM(FNAME,spectrum,N)
    USE Type_Kinds           , ONLY: FP, IP, DP => Double
    USE LBLRTMIO_Module

    IMPLICIT NONE

    CHARACTER(LEN=11), INTENT(IN)  :: FNAME
    INTEGER,           INTENT(IN) :: N
    REAL(DP), INTENT(OUT) :: spectrum(N)

    TYPE(LBLRTM_File_type) :: ofile
    INTEGER err_stat, I
    REAL(DP), ALLOCATABLE :: frequency(:)

    err_stat = LBLRTM_File_Read(ofile, FNAME)
    IF ( err_stat /= SUCCESS ) THEN
        print *, "handle error..."
        return
    END IF

    CALL LBLRTM_Layer_Frequency(oFile%Layer(1), frequency)

    DO I=1,N
        spectrum(I)=oFile%Layer(1)%Spectrum(I,1)
    ENDDO

    CALL LBLRTM_File_Destroy(ofile)

END SUBROUTINE GET_ODFILE_SPECTRUM

SUBROUTINE GET_ODFILE_FREQUENCY(FNAME,frequency,N)
    USE Type_Kinds           , ONLY: FP, IP, DP => Double
    USE LBLRTMIO_Module

    IMPLICIT NONE

    CHARACTER(LEN=11), INTENT(IN)  :: FNAME
    INTEGER,           INTENT(IN) :: N
    REAL(DP), INTENT(OUT) :: frequency(N)

    TYPE(LBLRTM_File_type) :: ofile
    INTEGER err_stat, I
    REAL(DP), ALLOCATABLE :: frequency_tmp(:)

    err_stat = LBLRTM_File_Read(ofile, FNAME)
    IF ( err_stat /= SUCCESS ) THEN
        print *, "handle error..."
        return
    END IF

    CALL LBLRTM_Layer_Frequency(oFile%Layer(1), frequency_tmp)

    DO I=1,N
        frequency(I)=frequency_tmp(I)
    ENDDO

    CALL LBLRTM_File_Destroy(ofile)

END SUBROUTINE GET_ODFILE_FREQUENCY

SUBROUTINE GET_ODFILE_DVSIZE(FNAME,DV)

    USE Type_Kinds           , ONLY: FP, IP, DP => Double
    USE LBLRTMIO_Module

    IMPLICIT NONE

    CHARACTER(LEN=11), INTENT(IN)  :: FNAME
    REAL(DP), INTENT(OUT) :: DV

    TYPE(LBLRTM_File_type) :: ofile
    INTEGER err_stat, M, I
    REAL(DP), ALLOCATABLE :: frequency(:)

    err_stat = LBLRTM_File_Read(ofile, FNAME)
    IF ( err_stat /= SUCCESS ) THEN
        print *, "handle error..."
        return
    END IF


    CALL LBLRTM_Layer_Frequency(oFile%Layer(1), frequency)
    m=size(frequency)
    dv=0.0
 !   DO I=1,m-1
 !       dv=dv+( frequency(i)-frequency(i-1) )
 !   ENDDO
 !   dv=dv/(m-1)
    dv=frequency(2)-frequency(1)
    CALL LBLRTM_File_Destroy(ofile)

END SUBROUTINE GET_ODFILE_DVSIZE


SUBROUTINE ParseFile(FNAME)


    USE Type_Kinds           , ONLY: FP, IP, DP => Double
    USE LBLRTMIO_Module

    IMPLICIT NONE

    TYPE(LBLRTM_File_type) :: ofile
    INTEGER err_stat
    INTEGER:: i, n
    REAL(DP), ALLOCATABLE :: frequency(:)
    REAL(DP), ALLOCATABLE :: spectrum (:)
    REAL(DP), ALLOCATABLE :: transmission(:)
    REAL(DP) :: SUM1,SUM2
    CHARACTER(LEN=11) :: FNAME


    err_stat = LBLRTM_File_Read(ofile, FNAME)
    !err_stat = LBLRTM_File_Read(ofile, "TAPE3")
    !    err_stat = LBLRTM_File_Read(ofile, "TAPE12")
    IF ( err_stat /= SUCCESS ) THEN
        print *, "handle error..."
    END IF
    print *, "N layers=", ofile%n_Layers
    print *, "N spectra=", ofile%Layer(1)%n_Spectra
    print *, "N points=", ofile%Layer(1)%n_Points
    do i=1,10
        print *, i,  oFile%Layer(1)%Spectrum(i,1)
    end do

!    CALL LBLRTM_File_Inspect(ofile)

    CALL LBLRTM_Layer_Frequency(oFile%Layer(1), frequency)
    print *, size(frequency)
    print *, frequency(1), frequency(size(frequency))

    do i=1,10
        print *, i,  frequency(i), ' -> ', oFile%Layer(1)%Spectrum(i,1)
    end do
    do i=ofile%Layer(1)%n_Points-9,ofile%Layer(1)%n_Points
        print *, i,  frequency(i), ' -> ', oFile%Layer(1)%Spectrum(i,1)
    end do

    ! Now do some calculations:
    n=ofile%Layer(1)%n_Points
    allocate (spectrum(n))
    allocate (transmission(n))
    sum1=0.0d0
    sum2=0.0d0
    do i=1,ofile%Layer(1)%n_Points
        spectrum(i)=oFile%Layer(1)%Spectrum(i,1)
        sum1=sum1+frequency(i)
        sum2=sum2+spectrum(i)
        transmission(i)=exp(-1.0*spectrum(i))
    end do
    do i=n-9,n
        print *, i,  frequency(i), ' -> T -> ' , transmission(i)
    end do

    print * , 'TOTAL ', sum1,sum2

end subroutine ParseFile


