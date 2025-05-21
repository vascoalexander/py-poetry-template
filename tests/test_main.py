from my_project_name.main import main

def test_main(capsys):
    main()
    captured = capsys.readouterr()
    assert "Hello, world from your new Python project!" in captured.out
    assert "Python version:" in captured.out
